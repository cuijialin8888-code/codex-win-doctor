BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'TestBootstrap.ps1')

    function Get-TestPlatform {
        [pscustomobject][ordered]@{
            windowsName           = 'Windows 11'
            windowsEdition        = 'Professional'
            windowsDisplayVersion = '25H2'
            osBuild               = '26200'
            osArchitecture        = 'X64'
            processArchitecture   = 'x64'
            powerShellVersion     = '7.6.0'
            powerShellEdition     = 'Core'
            powerShellExecutable  = 'C:\Users\Example\pwsh.exe'
        }
    }
}

Describe 'Machine-readable output' {
    It 'produces valid JSON with the expected summary' {
        $checks = @(
            New-DoctorCheck -Id 'test.json' -Category 'Tests' -Status 'PASS' -Summary 'JSON works'
        )
        $report = New-DoctorReport -Platform (Get-TestPlatform) -Checks $checks
        $json = ConvertTo-DoctorJson -Report $report
        $parsed = $json | ConvertFrom-Json

        $parsed.tool.version | Should -Be '0.1.0'
        $parsed.summary.pass | Should -Be 1
    }

    It 'does not leak a fake token through JSON evidence' {
        $fakeToken = 'sk-test-THIS_IS_NOT_REAL'
        $checks = @(
            New-DoctorCheck -Id 'test.secret' -Category 'Tests' -Status 'WARN' -Summary 'Secret test' `
                -Evidence ([pscustomobject]@{ message = ('OPENAI_API_KEY={0}' -f $fakeToken) })
        )
        $report = New-DoctorReport -Platform (Get-TestPlatform) -Checks $checks
        $json = ConvertTo-DoctorJson -Report $report

        $json | Should -Not -Match ([regex]::Escape($fakeToken))
    }
}

Describe 'Issue report output' {
    It 'produces a copyable Markdown report' {
        $checks = @(
            New-DoctorCheck -Id 'test.markdown' -Category 'Tests' -Status 'WARN' -Summary 'Markdown warning' -Details 'Details'
        )
        $report = New-DoctorReport -Platform (Get-TestPlatform) -Checks $checks
        $markdown = ConvertTo-DoctorIssueReport -Report $report

        $markdown | Should -Match '# Codex Windows Doctor Report'
        $markdown | Should -Match '## Warnings'
        $markdown | Should -Match 'test.markdown'
    }
}

Describe 'Shareable output privacy canary' {
    It 'removes the canary secret from Console, JSON, and IssueReport output' {
        $canary = 'CWD-CANARY-SECRET-9f3a7b2c'
        $checks = @(
            New-DoctorCheck -Id 'test.canary' -Category 'Tests' -Status 'WARN' `
                -Summary ('Authorization: Bearer {0}' -f $canary) `
                -Details ('OPENAI_API_KEY={0}' -f $canary) `
                -Recommendation @('GH_TOKEN={0}' -f $canary) `
                -Evidence ([pscustomobject]@{
                    authorization = 'Bearer {0}' -f $canary
                    api_key       = $canary
                    token         = $canary
                    message       = 'Authorization=Bearer {0}' -f $canary
                })
        )
        $report = New-DoctorReport -Platform (Get-TestPlatform) -Checks $checks
        $outputs = @(
            Format-DoctorConsole -Report $report
            ConvertTo-DoctorJson -Report $report
            ConvertTo-DoctorIssueReport -Report $report
        )

        foreach ($output in $outputs) {
            ([regex]::Matches($output, [regex]::Escape($canary))).Count | Should -Be 0
            $output | Should -Match 'REDACTED'
        }
        { $outputs[1] | ConvertFrom-Json } | Should -Not -Throw
    }
}
