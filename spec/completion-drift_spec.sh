# shellcheck shell=bash disable=all
Describe 'scripts/completion-drift.sh'
  drift() { bash ./scripts/completion-drift.sh ./spec/fixtures/fake-cli "$@"; }

  It 'reports no drift when the completion file covers the help output'
    When call drift spec/fixtures/_fake_in_sync
    The status should be success
    The output should include 'No drift found.'
    The output should include '9.9.9'
  End

  It 'reports missing subcommands, aliases and flags, and stale flags'
    When call drift spec/fixtures/_fake_drifted
    The status should equal 1
    The output should include '`./spec/fixtures/fake-cli kill`'
    The output should include '`--gamma` (`./spec/fixtures/fake-cli sub`)'
    The output should include '- `--removed`'
    The output should not include 'not-a-flag'
    The output should not include 'fake-cli help'
  End

  It 'fails with a usage error when the completion file is missing'
    When call drift spec/fixtures/does-not-exist
    The status should equal 2
    The stderr should include 'cannot read completion file'
  End

  Describe 'incomplete help traversal'
    Parameters
      root error
      root empty
      root timeout
      child error
      child empty
      child timeout
    End

    failed_help() {
      fixture=$(mktemp -d) || return
      cat > "$fixture/cli" <<'CLI'
#!/bin/sh
if [ "$*" = --version ]; then
  printf '%s\n' '9.9.9'
  exit 0
fi
if { [ "$HELP_LEVEL" = root ] && [ "$*" = --help ]; } ||
   { [ "$HELP_LEVEL" = child ] && [ "$*" = 'sub --help' ]; }; then
  case "$HELP_MODE" in
    error) printf '%s\n' 'help failed' >&2; exit 42 ;;
    empty) exit 0 ;;
    timeout) exit 124 ;;
  esac
fi
printf '%s\n' 'Usage: demo' 'Commands:' '  sub  Nested command' 'Options:' '  --alpha  Alpha option'
CLI
      chmod +x "$fixture/cli"
      printf '%s\n' 'sub --alpha' > "$fixture/completion"
      HELP_LEVEL=$1 HELP_MODE=$2 bash ./scripts/completion-drift.sh \
        "$fixture/cli" "$fixture/completion"
      result=$?
      rm -rf -- "$fixture"
      return "$result"
    }

    It "fails instead of reporting a clean comparison for $1 $2 help"
      When call failed_help "$1" "$2"
      The status should equal 2
      The output should not include 'No drift found.'
      The stderr should include 'help'
    End
  End
End
