Set-StrictMode -Version 2.0

function Format-DoctorConsole {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Report
    )

    $safeReport = ConvertTo-DoctorSafeData -InputObject $Report
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add(('{0} {1}' -f $safeReport.tool.name, $safeReport.tool.version))
    $lines.Add('')
    $lines.Add('Environment')
    $windowsText = '{0} {1}' -f $safeReport.platform.windowsName, $safeReport.platform.windowsDisplayVersion
    $lines.Add(('  Windows:      {0} (build {1}, {2})' -f $windowsText.Trim(), $safeReport.platform.osBuild, $safeReport.platform.osArchitecture))
    $lines.Add(('  PowerShell:   {0} ({1})' -f $safeReport.platform.powerShellVersion, $safeReport.platform.powerShellEdition))
    $lines.Add(('  Architecture: process {0}' -f $safeReport.platform.processArchitecture))
    $lines.Add('')
    $lines.Add('Checks')
    foreach ($check in $safeReport.checks) {
        $lines.Add(('  [{0}] {1}' -f $check.status, $check.summary))
    }
    $lines.Add('')
    $lines.Add('Summary')
    $lines.Add(('  PASS: {0}  WARN: {1}  FAIL: {2}  INFO: {3}  UNKNOWN: {4}' -f
            $safeReport.summary.pass,
            $safeReport.summary.warn,
            $safeReport.summary.fail,
            $safeReport.summary.info,
            $safeReport.summary.unknown))
    $lines.Add(('  Overall: {0}' -f $safeReport.overall))

    if (@($safeReport.recommendedNextSteps).Count -gt 0) {
        $lines.Add('')
        $lines.Add('Recommended next steps')
        $index = 1
        foreach ($recommendation in $safeReport.recommendedNextSteps) {
            $lines.Add(('  {0}. {1}' -f $index, $recommendation))
            $index++
        }
    }

    $lines.Add('')
    $lines.Add('Privacy: redaction enabled; no telemetry; no network requests.')
    return ($lines -join [Environment]::NewLine)
}

function ConvertTo-DoctorJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Report
    )

    $safeReport = ConvertTo-DoctorSafeData -InputObject $Report
    return ($safeReport | ConvertTo-Json -Depth 12)
}

function ConvertTo-DoctorIssueReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Report
    )

    $safeReport = ConvertTo-DoctorSafeData -InputObject $Report
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# Codex Windows Doctor Report')
    $lines.Add('')
    $lines.Add('> Sensitive-looking values and user-profile paths are redacted by default. Review this report before posting it publicly.')
    $lines.Add('')
    $lines.Add(('Doctor version: `{0}`  ' -f $safeReport.tool.version))
    $lines.Add(('Generated: `{0}`  ' -f $safeReport.timestamp))
    $lines.Add(('Overall: **{0}**' -f $safeReport.overall))
    $lines.Add('')
    $lines.Add('## Environment')
    $lines.Add('')
    $lines.Add(('- Windows: {0} {1}, build {2}, edition {3}' -f $safeReport.platform.windowsName, $safeReport.platform.windowsDisplayVersion, $safeReport.platform.osBuild, $safeReport.platform.windowsEdition))
    $lines.Add(('- OS architecture: {0}' -f $safeReport.platform.osArchitecture))
    $lines.Add(('- Process architecture: {0}' -f $safeReport.platform.processArchitecture))
    $lines.Add(('- PowerShell: {0} ({1})' -f $safeReport.platform.powerShellVersion, $safeReport.platform.powerShellEdition))
    $lines.Add(('- PowerShell executable: `{0}`' -f $safeReport.platform.powerShellExecutable))
    $lines.Add('')
    $lines.Add('## Checks')
    $lines.Add('')
    $lines.Add('| Status | Check ID | Summary |')
    $lines.Add('| --- | --- | --- |')
    foreach ($check in $safeReport.checks) {
        $summary = ([string]$check.summary).Replace('|', '\|').Replace("`r", ' ').Replace("`n", ' ')
        $lines.Add(('| {0} | `{1}` | {2} |' -f $check.status, $check.id, $summary))
    }

    foreach ($section in @(
            [pscustomobject]@{ Heading = 'Failures'; Status = 'FAIL' },
            [pscustomobject]@{ Heading = 'Warnings'; Status = 'WARN' },
            [pscustomobject]@{ Heading = 'Unknown checks'; Status = 'UNKNOWN' }
        )) {
        $matching = @($safeReport.checks | Where-Object { $_.status -eq $section.Status })
        if ($matching.Count -gt 0) {
            $lines.Add('')
            $lines.Add(('## {0}' -f $section.Heading))
            foreach ($check in $matching) {
                $lines.Add('')
                $lines.Add(('### `{0}`' -f $check.id))
                $lines.Add('')
                $lines.Add(('- Summary: {0}' -f $check.summary))
                if (-not [string]::IsNullOrWhiteSpace([string]$check.details)) {
                    $lines.Add(('- Details: {0}' -f $check.details))
                }
                foreach ($recommendation in @($check.recommendation)) {
                    $lines.Add(('- Recommendation: {0}' -f $recommendation))
                }
            }
        }
    }

    $lines.Add('')
    $lines.Add('## Summary')
    $lines.Add('')
    $lines.Add(('- PASS: {0}' -f $safeReport.summary.pass))
    $lines.Add(('- WARN: {0}' -f $safeReport.summary.warn))
    $lines.Add(('- FAIL: {0}' -f $safeReport.summary.fail))
    $lines.Add(('- INFO: {0}' -f $safeReport.summary.info))
    $lines.Add(('- UNKNOWN: {0}' -f $safeReport.summary.unknown))
    $lines.Add('')
    $lines.Add('No telemetry was sent. Codex Windows Doctor does not read authentication files or upload credentials.')
    return ($lines -join [Environment]::NewLine)
}

function Write-DoctorOutputFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $parent = [System.IO.Path]::GetDirectoryName($fullPath)
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
        throw ('Output directory does not exist: {0}' -f $parent)
    }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($fullPath, $Content, $encoding)
}
