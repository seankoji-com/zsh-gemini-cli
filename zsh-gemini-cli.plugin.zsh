# zsh-gemini-cli — completions and aliases for the Gemini CLI.
#
# The completion body lives in completions/_gemini and is autoloaded on the
# first Tab rather than sourced at startup.

0=${(%):-%N}
ZSH_GEMINI_CLI_DIR=${0:A:h}

fpath+=("$ZSH_GEMINI_CLI_DIR/completions")

# compdef only exists after compinit. When this plugin loads first, defer the
# registrations until compinit has run rather than dropping them silently,
# which is what a bare `compdef` call does here.
if (( $+functions[compdef] )); then
  compdef _gemini_cli gemini
  compdef _gemini_cli gm
else
  autoload -Uz add-zsh-hook
  _zsh_gemini_cli_late_compdef() {
    (( $+functions[compdef] )) || return 0
    compdef _gemini_cli gemini
    compdef _gemini_cli gm
    add-zsh-hook -d precmd _zsh_gemini_cli_late_compdef
  }
  add-zsh-hook precmd _zsh_gemini_cli_late_compdef
fi

alias gm='gemini'
alias gmm='gemini mcp'
alias gme='gemini extensions'
