# shellcheck shell=bash disable=all
Describe 'completion loading with real compinit'
  Parameters
    before
    after
  End
  It "autoloads every registered command when compinit runs $1 plugin loading"
    run_it() {
      zsh -f -c '
        autoload -Uz compinit
        [[ "$1" == before ]] && compinit -D
        source ./zsh-gemini-cli.plugin.zsh
        if [[ "$1" == after ]]; then
          compinit -D
          _zsh_gemini_cli_late_compdef
        fi
        for command_name in gemini gm; do
          ( autoload +X "$_comps[$command_name]" ) || return
        done
      ' test "$1"
    }
    When call run_it "$1"
    The status should be success
    The stderr should equal ''
  End
End
