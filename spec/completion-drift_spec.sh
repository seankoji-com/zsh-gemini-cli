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
End
