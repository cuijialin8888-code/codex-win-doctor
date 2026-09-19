#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Json,

    [Parameter(Mandatory = $false)]
    [switch]$IssueReport,

    [Parameter(Mandatory = $false)]
    [switch]$Sarif,

    [Parameter(Mandatory = $false)]
    [ValidateSet('None', 'Fail', 'Warn', 'Unknown')]
    [string]$FailOn = 'None',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Output
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$selectedFormats = @(
    if ($Json) { 'Json' }
    if ($IssueReport) { 'IssueReport' }
    if ($Sarif) { 'Sarif' }
)
if ($selectedFormats.Count -gt 1) {
    throw 'Choose only one of -Json, -IssueReport, or -Sarif.'
}

$sourceFiles = @(
    'src/Core/Framework.ps1',
    'src/Core/Process.ps1',
    'src/Privacy/Redaction.ps1',
    'src/Checks/Platform.ps1',
    'src/Checks/Commands.ps1',
    'src/Checks/Codex.ps1',
    'src/Checks/Filesystem.ps1',
    'src/Checks/WindowsFeatures.ps1',
    'src/Output/Renderers.ps1',
    'src/Invoke-CodexDoctor.ps1'
)

foreach ($sourceFile in $sourceFiles) {
    . (Join-Path -Path $PSScriptRoot -ChildPath $sourceFile)
}

$format = 'Console'
if ($Json) {
    $format = 'Json'
}
elseif ($IssueReport) {
    $format = 'IssueReport'
}
elseif ($Sarif) {
    $format = 'Sarif'
}
elseif ($Output) {
    $extension = [System.IO.Path]::GetExtension($Output)
    if ($extension -ieq '.json') {
        $format = 'Json'
    }
    elseif ($extension -ieq '.md') {
        $format = 'IssueReport'
    }
    elseif ($extension -ieq '.sarif') {
        $format = 'Sarif'
    }
}

Write-Verbose 'Running local, read-only Codex environment checks.'
$report = Invoke-CodexDoctor -WorkspacePath (Get-Location).Path -Verbose:$VerbosePreference

switch ($format) {
    'Json' {
        $rendered = ConvertTo-DoctorJson -Report $report
    }
    'IssueReport' {
        $rendered = ConvertTo-DoctorIssueReport -Report $report
    }
    'Sarif' {
        $rendered = ConvertTo-DoctorSarif -Report $report
    }
    default {
        $rendered = Format-DoctorConsole -Report $report
    }
}

if ($Output) {
    Write-DoctorOutputFile -Path $Output -Content $rendered
    if ($format -eq 'Console') {
        Write-Output ('Report written to {0}' -f (ConvertTo-DoctorSafeText -Text ([System.IO.Path]::GetFullPath($Output))))
    }
}
else {
    Write-Output $rendered
}

$gateFailures = @(Get-DoctorGateFailure -Checks $report.checks -FailOn $FailOn)
if ($gateFailures.Count -gt 0) {
    $statuses = @($gateFailures | ForEach-Object { [string]$_.status } | Sort-Object -Unique)
    $message = 'Diagnostic policy gate triggered at {0}: {1} check(s) ({2}).' -f `
        $FailOn, $gateFailures.Count, ($statuses -join ', ')
    [Console]::Error.WriteLine((ConvertTo-DoctorSafeText -Text $message))
    exit 1
}
