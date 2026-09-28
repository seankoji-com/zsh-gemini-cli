#!/usr/bin/env bash
# Compare a CLI's --help output against a zsh completion file.
#
# Usage: scripts/completion-drift.sh <cli> <completion-file> [max-depth]
#
# Walks `<cli> --help` and the --help of every subcommand it lists (down to
# max-depth levels, default 4), collects the flags and subcommand names, and
# reports:
#   - flags and subcommands the CLI shows that the completion file never names
#   - long flags the completion file names that no --help output shows
#
# The presence check is file-wide, not per subcommand, so it catches missing
# and removed options without having to parse zsh _arguments specs.
#
# Prints a Markdown report. Exits 0 when in sync, 1 on drift, 2 on usage error.

set -uo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <cli> <completion-file> [max-depth]" >&2
  exit 2
fi

cli=$1
comp=$2
max_depth=${3:-4}

if [[ ! -r $comp ]]; then
  echo "cannot read completion file: $comp" >&2
  exit 2
fi

run_help() {
  # A subcommand that ignores --help must not hang the run or wait on stdin.
  if command -v timeout >/dev/null 2>&1; then
    timeout 30 "$cli" "$@" --help </dev/null 2>/dev/null
  else
    "$cli" "$@" --help </dev/null 2>/dev/null
  fi
}

# Option lines start with a short indent and a dash; wrapped description
# lines are indented further, so a flag named in one is not an option line. Keep only the option spec
# (everything before the first run of two spaces) so flags mentioned in a
# description are not mistaken for real ones.
extract_flags() {
  sed -nE 's/^ {1,8}(-.*)$/\1/p' |
    sed -E 's/ {2,}.*$//' |
    grep -oE '(^|[ ,])--?[A-Za-z][A-Za-z0-9-]*' |
    sed -E 's/^[ ,]*//'
}

# Subcommand names from the "Commands:" section. Handles both commander-style
# lines ("  stop|kill <id>  ...") and yargs-style lines ("  gemini mcp add ...").
# $1 is the space-separated command path (the CLI name plus parents).
extract_commands() {
  local path=$1
  awk -v path="$path" '
    BEGIN { n = split(path, parent, " ") }
    /^Commands:/ { in_cmds = 1; next }
    in_cmds && /^[^[:space:]]/ { in_cmds = 0 }
    in_cmds && /^  [^[:space:]]/ {
      split($0, tok, " ")
      i = 1
      for (j = 1; j <= n; j++) if (tok[i] == parent[j]) i++
      name = tok[i]
      if (name !~ /^[a-z][a-z0-9|-]*$/) next
      k = split(name, alias, "|")
      for (a = 1; a <= k; a++) if (alias[a] != "help") print (a == 1 ? "" : "=") alias[a]
      if (match($0, /\[aliases: [^]]*\]/)) {
        list = substr($0, RSTART + 10, RLENGTH - 11)
        m = split(list, more, /, */)
        for (b = 1; b <= m; b++) print "=" more[b]
      }
    }
  '
}

# The completion file minus comment lines, read once. Kept in a variable
# rather than piped per lookup: with pipefail, `grep -q` exiting early would
# SIGPIPE the producer and turn a match into a failure.
comp_body=$(grep -v '^[[:space:]]*#' "$comp")

# Word-boundary match: "--model" must not be satisfied by "--model-foo".
in_completion() {
  grep -qE -- "(^|[^A-Za-z0-9_-])$1([^A-Za-z0-9_-]|\$)" <<<"$comp_body"
}

declare -a missing_flags=() missing_cmds=() stale_flags=()
declare -A seen_flags=()

walk() {
  local depth=$1
  shift
  local help name
  help=$(run_help "$@") || true
  [[ -n $help ]] || return 0

  while IFS= read -r flag; do
    [[ -n $flag ]] || continue
    if [[ -z ${seen_flags[$flag]:-} ]]; then
      seen_flags[$flag]=1
      in_completion "$flag" || missing_flags+=("\`$flag\` (\`$cli${*:+ $*}\`)")
    fi
  done < <(printf '%s\n' "$help" | extract_flags | sort -u)

  while IFS= read -r name; do
    [[ -n $name ]] || continue
    local alias_only=
    if [[ $name == =* ]]; then
      alias_only=1
      name=${name#=}
    fi
    in_completion "$name" || missing_cmds+=("\`$cli${*:+ $*} $name\`")
    if [[ -z $alias_only ]] && (( depth < max_depth )); then
      walk $((depth + 1)) "$@" "$name"
    fi
  done < <(printf '%s\n' "$help" | extract_commands "$cli $*")
}

walk 1

while IFS= read -r flag; do
  [[ -n ${seen_flags[$flag]:-} ]] || stale_flags+=("\`$flag\`")
done < <(grep -oE -- '--[A-Za-z][A-Za-z0-9-]*' <<<"$comp_body" | sort -u)

if (( ${#seen_flags[@]} == 0 )); then
  echo "no flags found in \`$cli --help\` output; is $cli installed?" >&2
  exit 2
fi

version=$("$cli" --version </dev/null 2>/dev/null | tail -1)
total=$(( ${#missing_flags[@]} + ${#missing_cmds[@]} + ${#stale_flags[@]} ))

echo "Checked \`$(basename "$comp")\` against \`$cli --help\` (${version:-unknown version})."
echo
if (( total == 0 )); then
  echo "No drift found."
  exit 0
fi

section() {
  local title=$1
  shift
  (( $# )) || return 0
  echo "### $title"
  echo
  printf -- '- %s\n' "$@"
  echo
}

section "Subcommands missing from the completion file" "${missing_cmds[@]}"
section "Flags missing from the completion file" "${missing_flags[@]}"
section "Flags in the completion file that no --help shows" "${stale_flags[@]}"
exit 1
