# shellcheck shell=bash disable=all
# Spot checks that completions/_gemini tracks `gemini --help`. The weekly
# completion-drift workflow does the full comparison against the live CLI.
Describe 'completions/_gemini'
  Describe 'new flags'
    Parameters
      --acp
      --admin-policy
      --session-file
      --session-id
      --skip-trust
      --worktree
      --skip-settings
    End

    It "completes the $1 flag"
      When call grep -cE -- "(^|[^a-z-])$1([^a-z-]|\$)" completions/_gemini
      The output should not equal 0
    End
  End

  Describe 'subcommands'
    Parameters
      gemma
      extension
      skill
      hook
    End

    It "lists the $1 subcommand"
      When call grep -cF -- "'$1:" completions/_gemini
      The output should not equal 0
    End
  End

  It 'lists the gemma subcommands'
    When call grep -cE -- "'(setup|start|stop|status|logs):" completions/_gemini
    The output should equal 5
  End

  It 'loads without errors'
    When call zsh -n completions/_gemini
    The status should be success
  End
End

Describe 'models completion dispatch'
  # Stub zsh's completion primitives to exercise the command dispatch and inspect
  # the actual argument specifications passed to _arguments.
  run_completion() {
    MODE="$1" zsh -f -c '
      _arguments() {
        if [[ "$1" == -C ]]; then
          if [[ "$MODE" == commands ]]; then
            state=command
          elif [[ "$MODE" == models ]]; then
            state=args
            line=(models)
          else
            print -rl -- "$@"
          fi
        else
          print -rl -- "$@"
        fi
      }
      _describe() { print -rl -- "${commands[@]}"; }
      source completions/_gemini
    '
  }

  It 'offers models as a command'
    When call run_completion commands
    The output should include 'models:Manage or list Gemini models'
  End

  It 'offers the top-level list-models flag'
    When call run_completion flags
    The output should include '--list-models[List available Gemini models and exit]'
  End

  It 'dispatches models and offers its output formats and help'
    When call run_completion models
    The output should include '--output-format[Output format]:format:(text json)'
    The output should include '--help[Show help]'
    The output should include '--debug[Debug mode]'
    The output should not include 'stream-json'
  End
End
