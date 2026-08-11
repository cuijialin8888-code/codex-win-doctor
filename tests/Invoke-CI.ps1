#requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$parseIssues = New-Object System.Collections.Generic.List[string]
foreach ($file in Get-ChildItem -LiteralPath $projectRoot -Recurse -Include '*.ps1', '*.psd1') {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    foreach ($parseIssue in @($errors)) {
        $parseIssues.Add(('{0}:{1}: {2}' -f $file.FullName, $parseIssue.Extent.StartLineNumber, $parseIssue.Message))
    }
}
if ($parseIssues.Count -gt 0) {
    throw ($parseIssues -join [Environment]::NewLine)
}

$invokePester = Get-Command -Name 'Invoke-Pester' -ErrorAction SilentlyContinue
if ($null -eq $invokePester) {
    throw 'Pester 5 or later is required for development tests. It is not required to run codex-doctor.ps1.'
}

$configuration = New-PesterConfiguration
$configuration.Run.Path = $PSScriptRoot
$configuration.Run.PassThru = $true
$configuration.Output.Verbosity = 'Detailed'
$result = Invoke-Pester -Configuration $configuration
if ($result.FailedCount -gt 0) {
    throw ('Pester reported {0} failed test(s).' -f $result.FailedCount)
}

$invokeAnalyzer = Get-Command -Name 'Invoke-ScriptAnalyzer' -ErrorAction SilentlyContinue
if ($null -ne $invokeAnalyzer) {
    $settings = Join-Path -Path $projectRoot -ChildPath '.psscriptanalyzer.psd1'
    $findings = @(Invoke-ScriptAnalyzer -Path $projectRoot -Recurse -Settings $settings)
    if ($findings.Count -gt 0) {
        $findings | Format-Table -AutoSize
        throw ('PSScriptAnalyzer reported {0} finding(s).' -f $findings.Count)
    }
}
else {
    Write-Warning 'PSScriptAnalyzer is not installed; static analysis was skipped.'
}
