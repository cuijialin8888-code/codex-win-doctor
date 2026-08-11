BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'TestBootstrap.ps1')
}

Describe 'CODEX_HOME diagnostics' {
    It 'reports INFO when CODEX_HOME is unset and the default path is absent' {
        $defaultPath = Join-Path -Path $TestDrive -ChildPath 'not-created-default'
        $check = Test-CodexHome -CodexHomeOverride '' -DefaultPath $defaultPath

        $check.status | Should -Be 'INFO'
        $check.evidence.configured | Should -BeFalse
    }

    It 'reports WARN when CODEX_HOME points to a missing directory' {
        $configuredPath = Join-Path -Path $TestDrive -ChildPath 'missing-custom-home'
        $defaultPath = Join-Path -Path $TestDrive -ChildPath 'not-created-default'
        $check = Test-CodexHome -CodexHomeOverride $configuredPath -DefaultPath $defaultPath

        $check.status | Should -Be 'WARN'
        $check.evidence.selectedPathExists | Should -BeFalse
    }
}

Describe 'Disposable write probes' {
    It 'writes and cleans up its temporary file' {
        $probe = Test-DoctorDirectoryWrite -Path $TestDrive

        $probe.writable | Should -BeTrue
        $probe.cleanedUp | Should -BeTrue
        @(Get-ChildItem -LiteralPath $TestDrive -Filter '.codex-doctor-write-*.tmp').Count | Should -Be 0
    }
}
