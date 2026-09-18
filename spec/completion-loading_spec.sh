# shellcheck shell=bash disable=all
Describe 'completion loading with real compinit'
  Parameters
    before
    after
  End
  It "autoloads every registered command when compinit runs $1 plugin loading"
    run_it() {
      zsh -f -c '
        # Runner checkout parents can be group-writable. Test our plugin from
        # a private directory and ignore unrelated insecure system fpath entries.
        fixture=$(mktemp -d) || return
        TRAPEXIT() { rm -rf -- "$fixture"; }
        mkdir "$fixture/completions"
        cp ./zsh-gemini-cli.plugin.zsh "$fixture/"
        cp ./completions/_gemini "$fixture/completions/"
        autoload -Uz compinit
        [[ "$1" == before ]] && compinit -D -i
        source "$fixture/zsh-gemini-cli.plugin.zsh"
        if [[ "$1" == after ]]; then
          compinit -D -i
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
