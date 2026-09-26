# zsh-gemini-cli

Zsh completions and aliases for the [Gemini CLI](https://github.com/google-gemini/gemini-cli).

The plugin adds a completion definition (`completions/_gemini`) to your `fpath` and registers it for the `gemini` and `gm` commands. Completions are autoloaded on the first Tab press rather than sourced at startup. If the plugin loads before `compinit`, the `compdef` registrations are deferred via a `precmd` hook and applied once `compinit` has run, so they are never silently dropped. Completion covers top-level flags (`--model`, `--prompt`, `--approval-mode`, `--output-format`, `--resume`, etc.) and the `mcp`, `extensions`, `skills`, `hooks`, and `gemma` subcommands (plus the `extension`, `skill`, and `hook` aliases) along with their nested subcommands and options. A weekly workflow compares the completions against the latest Gemini CLI release and opens an issue when they drift (see [Keeping completions current](#keeping-completions-current)).

## Installation

### Manual

Clone the repo and source the plugin from your `.zshrc`:

```zsh
git clone https://github.com/seankoji-com/zsh-gemini-cli ~/.zsh/zsh-gemini-cli
echo 'source ~/.zsh/zsh-gemini-cli/zsh-gemini-cli.plugin.zsh' >> ~/.zshrc
```

Make sure `compinit` is initialized in your `.zshrc` for completions to work:

```zsh
autoload -Uz compinit && compinit
```

### zinit

```zsh
zinit light seankoji-com/zsh-gemini-cli
```

### oh-my-zsh

Clone into your custom plugins directory:

```zsh
git clone https://github.com/seankoji-com/zsh-gemini-cli \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-gemini-cli
```

Then add it to the `plugins` array in your `.zshrc`:

```zsh
plugins=(... zsh-gemini-cli)
```

## Usage

Tab completion is available for `gemini` and `gm` once the plugin is loaded.

The following aliases are provided:

| Alias  | Expands to            |
|--------|-----------------------|
| `gm`   | `gemini`              |
| `gmm`  | `gemini mcp`          |
| `gme`  | `gemini extensions`   |

## Keeping completions current

`scripts/completion-drift.sh` walks `gemini --help` and every subcommand's `--help`, then lists flags and subcommands missing from `completions/_gemini` and flags the completion file still offers that the CLI dropped:

```zsh
scripts/completion-drift.sh gemini completions/_gemini
```

It needs bash 4 or later. The `completion-drift` workflow runs it every Monday against the latest `@google/gemini-cli` from npm and opens or updates a single issue when it finds drift.

## License

MIT — see [LICENSE](LICENSE).
