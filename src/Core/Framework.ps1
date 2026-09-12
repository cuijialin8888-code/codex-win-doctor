Set-StrictMode -Version 2.0

$script:DoctorName = 'Codex Windows Doctor'
$script:DoctorVersion = '0.1.0'
$script:DoctorStatuses = @('PASS', 'WARN', 'FAIL', 'INFO', 'UNKNOWN')

function New-DoctorCheck {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'Creates an in-memory diagnostic object and does not change system state.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [ValidateSet('PASS', 'WARN', 'FAIL', 'INFO', 'UNKNOWN')]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Summary,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$Details = '',

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]]$Recommendation = @(),

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$Evidence = $null
    )

    [pscustomobject][ordered]@{
        id             = $Id
        category       = $Category
        status         = $Status
        summary        = $Summary
        details        = $Details
        recommendation = @($Recommendation)
        evidence       = $Evidence
    }
}

function Get-DoctorSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Checks
    )

    $counts = [ordered]@{
        pass    = 0
        warn    = 0
        fail    = 0
        info    = 0
        unknown = 0
    }

    foreach ($check in $Checks) {
        $key = ([string]$check.status).ToLowerInvariant()
        if ($counts.Contains($key)) {
            $counts[$key]++
        }
    }

    [pscustomobject]$counts
}

function Get-DoctorOverallStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Summary
    )

    if ($Summary.fail -gt 0) {
        return 'NEEDS ATTENTION'
    }
    if ($Summary.warn -gt 0) {
        return 'HEALTHY WITH WARNINGS'
    }
    if ($Summary.unknown -gt 0) {
        return 'INCOMPLETE - REVIEW UNKNOWN CHECKS'
    }
    return 'HEALTHY'
}

function Get-DoctorGateFailure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Checks,

        [Parameter(Mandatory = $false)]
        [ValidateSet('None', 'Fail', 'Warn', 'Unknown')]
        [string]$FailOn = 'None'
    )

    $statuses = @(switch ($FailOn) {
        'Fail' { @('FAIL') }
        'Warn' { @('FAIL', 'WARN') }
        'Unknown' { @('FAIL', 'WARN', 'UNKNOWN') }
        default { @() }
    })

    if ($statuses.Count -eq 0) {
        return @()
    }

    return @($Checks | Where-Object { $statuses -contains [string]$_.status })
}

function Get-DoctorRecommendation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Checks,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int]$Maximum = 5
    )

    $priority = @('FAIL', 'WARN', 'UNKNOWN')
    $recommendations = New-Object System.Collections.Generic.List[string]

    foreach ($status in $priority) {
        foreach ($check in @($Checks | Where-Object { $_.status -eq $status })) {
            foreach ($item in @($check.recommendation)) {
                if (-not [string]::IsNullOrWhiteSpace($item) -and -not $recommendations.Contains($item)) {
                    $recommendations.Add($item)
                    if ($recommendations.Count -ge $Maximum) {
                        return @($recommendations)
                    }
                }
            }
        }
    }

    return @($recommendations)
}

function New-DoctorReport {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'Creates an in-memory report object and does not change system state.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Platform,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Checks
    )

    $summary = Get-DoctorSummary -Checks $Checks
    [pscustomobject][ordered]@{
        tool                = [pscustomobject][ordered]@{
            name    = $script:DoctorName
            version = $script:DoctorVersion
        }
        timestamp           = [DateTimeOffset]::Now.ToString('o')
        platform            = $Platform
        checks              = @($Checks)
        summary             = $summary
        overall             = Get-DoctorOverallStatus -Summary $summary
        recommendedNextSteps = @(Get-DoctorRecommendation -Checks $Checks)
        privacy             = [pscustomobject][ordered]@{
            redaction = 'enabled'
            telemetry = 'disabled'
            network   = 'not used by this tool'
        }
    }
}
