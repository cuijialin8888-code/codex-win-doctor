#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Json,

    [Parameter(Mandatory = $false)]
    [switch]$IssueReport,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Output
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ($Json -and $IssueReport) {
    throw 'Choose either -Json or -IssueReport, not both.'
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
elseif ($Output) {
    $extension = [System.IO.Path]::GetExtension($Output)
    if ($extension -ieq '.json') {
        $format = 'Json'
    }
    elseif ($extension -ieq '.md') {
        $format = 'IssueReport'
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
