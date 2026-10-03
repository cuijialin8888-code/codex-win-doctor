BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'TestBootstrap.ps1')
}

Describe 'Bounded check group selection' {
    BeforeEach {
        Mock Test-CodexCli {
            New-DoctorCheck -Id 'codex.cli' -Category 'Codex' -Status 'PASS' -Summary 'Selected CLI check'
        }
        Mock Test-WorkspaceAndTempWrite { throw 'Unselected filesystem probe ran' }
    }

    It 'runs only a selected group and preserves report semantics' {
        $report = Invoke-CodexDoctor -WorkspacePath $TestDrive -CheckGroup @('codex.cli')
        @($report.checks).Count | Should -Be 1
        $report.checks[0].id | Should -Be 'codex.cli'
        Should -Invoke Test-CodexCli -Times 1 -Exactly
        Should -Invoke Test-WorkspaceAndTempWrite -Times 0 -Exactly
        (ConvertTo-DoctorJson -Report $report | ConvertFrom-Json).summary.pass | Should -Be 1
    }

    It 'rejects an unknown group before running any checks' {
        { Invoke-CodexDoctor -WorkspacePath $TestDrive -CheckGroup @('unknown.group') } | Should -Throw '*Unknown check group*'
        Should -Invoke Test-CodexCli -Times 0 -Exactly
        Should -Invoke Test-WorkspaceAndTempWrite -Times 0 -Exactly
    }

    It 'does not execute duplicate group requests twice' {
        $report = Invoke-CodexDoctor -WorkspacePath $TestDrive -CheckGroup @('codex.cli', 'CODEX.CLI')
        @($report.checks).Count | Should -Be 1
        Should -Invoke Test-CodexCli -Times 1 -Exactly
    }
}
