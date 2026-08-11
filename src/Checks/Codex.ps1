Set-StrictMode -Version 2.0

function Test-CodexCli {
    [CmdletBinding()]
    param()

    $probe = Get-DoctorCommandProbe -Name 'codex' -Arguments @('--version')
    $check = New-DoctorCommandCheck -Id 'codex.cli' -Category 'Codex' -DisplayName 'Codex CLI' `
        -Probe $probe -AbsentStatus 'INFO' `
        -AbsentDetails 'Codex CLI was not detected. This can be normal if you only use the Codex desktop app or have not installed the CLI.'

    if ($probe.state -eq 'Passed') {
        $directories = @($probe.allPaths | ForEach-Object { Split-Path -Parent $_ } | Sort-Object -Unique)
        if ($directories.Count -gt 1) {
            $check.status = 'WARN'
            $check.summary = 'Multiple Codex CLI installation locations were detected'
            $check.details = 'Different terminals or applications may resolve different Codex versions.'
            $check.recommendation = @('Review the listed Codex paths and decide which installation should be first on PATH. This tool will not modify PATH.')
        }
        else {
            $check.status = 'PASS'
            $check.summary = 'Codex CLI is executable'
        }
    }

    return $check
}

function Test-CodexDesktopPackage {
    [CmdletBinding()]
    param()

    $getAppxPackage = Get-Command -Name 'Get-AppxPackage' -ErrorAction SilentlyContinue
    if ($null -eq $getAppxPackage) {
        return New-DoctorCheck -Id 'codex.desktop' -Category 'Codex' -Status 'UNKNOWN' `
            -Summary 'Codex desktop package state cannot be queried' `
            -Details 'Get-AppxPackage is unavailable in this PowerShell environment.' `
            -Recommendation @('Use Get-AppxPackage -Name *Codex* in a standard PowerShell session and share only package metadata, never package contents or credentials.')
    }

    try {
        $packages = @(Get-AppxPackage -Name '*Codex*' -ErrorAction Stop)
        if ($packages.Count -eq 0) {
            return New-DoctorCheck -Id 'codex.desktop' -Category 'Codex' -Status 'INFO' `
                -Summary 'Codex desktop package not detected for the current user' `
                -Details 'This can be normal if you only use the CLI or another Codex client.'
        }

        $evidence = @()
        $problemPackages = @()
        foreach ($package in $packages) {
            $packageStatus = [string]$package.Status
            $evidence += [pscustomobject][ordered]@{
                name            = [string]$package.Name
                version         = [string]$package.Version
                architecture    = [string]$package.Architecture
                status          = $packageStatus
                installLocation = [string]$package.InstallLocation
            }
            if ($packageStatus -notin @('Ok', '')) {
                $problemPackages += $package
            }
        }

        if ($problemPackages.Count -gt 0) {
            return New-DoctorCheck -Id 'codex.desktop' -Category 'Codex' -Status 'WARN' `
                -Summary 'Codex desktop package reports a non-OK status' `
                -Details 'States such as Modified or NeedsRemediation require safe package troubleshooting; this tool does not modify WindowsApps or package permissions.' `
                -Recommendation @('Record the package status, restart Windows, and use Microsoft Store or organizational deployment support. Do not take ownership of WindowsApps or modify signed package files.') `
                -Evidence $evidence
        }

        return New-DoctorCheck -Id 'codex.desktop' -Category 'Codex' -Status 'PASS' `
            -Summary 'Codex desktop package detected' `
            -Details ('Detected {0} Codex package(s) for the current user.' -f $packages.Count) `
            -Evidence $evidence
    }
    catch {
        return New-DoctorCheck -Id 'codex.desktop' -Category 'Codex' -Status 'UNKNOWN' `
            -Summary 'Codex desktop package query failed' -Details $_.Exception.Message `
            -Recommendation @('Run Get-AppxPackage -Name *Codex* in a normal, non-elevated PowerShell session. Share package metadata only.')
    }
}
