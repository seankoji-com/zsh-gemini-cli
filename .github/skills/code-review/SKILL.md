---
name: code-review
description: Review priorities for zsh-gemini-cli pull requests, what deserves real scrutiny versus what to skip. Use for every PR review.
---

# Review priorities

This repo is a zsh plugin: a small loader (`zsh-gemini-cli.plugin.zsh`) plus
one large hand-written completion spec (`completions/_gemini`) for Google's
`gemini` CLI. PR history here is thin (5 closed PRs: mostly CI-template syncs
plus the initial README) — no recurring bug pattern to cite, so these
priorities come from the actual code and its test gaps instead.

## Spend real attention here

- **The `compdef` timing dance in `zsh-gemini-cli.plugin.zsh`.** A bare
  `compdef` call before `compinit` has run is silently discarded by zsh — no
  error, the completion just never registers. The plugin works around this
  with a `precmd` hook that retries and removes itself once `compdef` exists.
  This is the most failure-prone piece of the repo *because failures are
  silent*. `spec/zsh-gemini-cli_spec.sh` already asserts the fpath entry, the
  defer hook, and its self-removal — check a diff doesn't quietly break one of
  those rather than re-deriving the logic from scratch.
- **`completions/_gemini`'s `_arguments` specs.** This ~500-line file is the
  biggest surface in the repo and the least tested: shellspec only checks
  that line 1 is `#compdef gemini gm`, nothing asserts the arg-spec strings
  themselves are well-formed or match real `gemini` CLI flags. A malformed
  spec (unbalanced quotes/braces, wrong `:`-field count) doesn't error, it
  just silently drops or mis-completes that flag. Read new/changed
  `_arguments` blocks closely.
- **The subcommands that shell out and parse CLI output**
  (`_gemini_cli_mcp_{remove,enable,disable}`, `_gemini_cli_extensions_*`):
  they pipe `gemini mcp list` / `gemini extensions list` through
  `grep -E '^\s+\w+' | awk '{print $1...}'`. That's coupled to the real CLI's
  current output layout — flag changes to the pattern that aren't clearly
  tied to an upstream `gemini` output change.
- **Drift between `completions/_gemini` and README.md.** The alias table
  (`gm`/`gmm`/`gme`) and subcommand list in the README have no automated
  check against the real completion/alias definitions — flag it when a PR
  adds or renames a subcommand or alias in one place but not the other.

## Do not spend attention here

- `.github/workflows/*.yml` — reusable-workflow callers synced from the org's
  central `seankoji-com/.github` repo (most of this repo's PR history is
  exactly these sync commits). Treat edits here as mechanical, not
  repo-specific logic.
- `spec/spec_helper.sh` — ShellSpec harness boilerplate.
- `LICENSE`, `.gitignore`, `.shellspec` — static config, no logic.
- README wording/formatting, except where it actually drifts from behavior
  (see the drift bullet above) — not worth a style comment.

## Comment style

- One comment per real issue, not one per file/line it repeats in.
- Don't restate what `shellspec` already asserts (fpath entry, alias values,
  and defer-hook lifecycle are covered by `spec/zsh-gemini-cli_spec.sh`) or
  what CodeQL already flags.
