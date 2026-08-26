# shellcheck shell=bash disable=all
Describe 'zsh-gemini-cli.plugin.zsh'
  Include ./zsh-gemini-cli.plugin.zsh

  Describe 'completions'
    It 'adds its completions directory to fpath'
      When call print -r -- "${fpath[(r)*zsh-gemini-cli/completions]}"
      The output should end with 'zsh-gemini-cli/completions'
    End

    It 'ships a completion file for the right commands'
      When call head -1 completions/_gemini
      The output should equal '#compdef gemini gm'
    End

    # A bare compdef call before compinit is silently discarded, so the
    # registrations are deferred to a precmd hook instead.
    It 'defers registration when compdef does not exist yet'
      When call print -r -- "${precmd_functions[(r)_zsh_gemini_cli_late_compdef]}"
      The output should equal '_zsh_gemini_cli_late_compdef'
    End

    It 'removes its own deferral hook once it has run'
      run_it() {
        compdef() { :; }
        _zsh_gemini_cli_late_compdef
        print -r -- "[${precmd_functions[(r)_zsh_gemini_cli_late_compdef]}]"
      }
      When call run_it
      The output should equal '[]'
    End
  End

  Describe 'aliases'
    Parameters
      gm   'gemini'
      gmm  'gemini mcp'
      gme  'gemini extensions'
    End

    It "defines $1"
      When call print -r -- "${aliases[$1]}"
      The output should equal "$2"
    End
  End
End
