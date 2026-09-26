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
