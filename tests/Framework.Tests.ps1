BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'TestBootstrap.ps1')
}

Describe 'Diagnostic framework' {
    It 'creates a check with the required schema' {
        $check = New-DoctorCheck -Id 'test.schema' -Category 'Tests' -Status 'PASS' -Summary 'Schema works'

        @($check.PSObject.Properties.Name) | Should -Contain 'id'
        @($check.PSObject.Properties.Name) | Should -Contain 'category'
        @($check.PSObject.Properties.Name) | Should -Contain 'status'
        @($check.PSObject.Properties.Name) | Should -Contain 'summary'
        @($check.PSObject.Properties.Name) | Should -Contain 'details'
        @($check.PSObject.Properties.Name) | Should -Contain 'recommendation'
        @($check.PSObject.Properties.Name) | Should -Contain 'evidence'
    }

    It 'counts WARN separately from FAIL' {
        $checks = @(
            (New-DoctorCheck -Id 'test.pass' -Category 'Tests' -Status 'PASS' -Summary 'Pass')
            (New-DoctorCheck -Id 'test.warn' -Category 'Tests' -Status 'WARN' -Summary 'Warn')
            (New-DoctorCheck -Id 'test.info' -Category 'Tests' -Status 'INFO' -Summary 'Info')
        )
        $summary = Get-DoctorSummary -Checks $checks

        $summary.pass | Should -Be 1
        $summary.warn | Should -Be 1
        $summary.fail | Should -Be 0
        (Get-DoctorOverallStatus -Summary $summary) | Should -Be 'HEALTHY WITH WARNINGS'
    }

    It 'limits recommended next steps' {
        $checks = 1..7 | ForEach-Object {
            New-DoctorCheck -Id ('test.warn.{0}' -f $_) -Category 'Tests' -Status 'WARN' `
                -Summary 'Warn' -Recommendation @('Recommendation {0}' -f $_)
        }

        @(Get-DoctorRecommendation -Checks $checks -Maximum 3).Count | Should -Be 3
    }
}
