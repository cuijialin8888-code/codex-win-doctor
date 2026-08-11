Set-StrictMode -Version 2.0

function Test-PathHealth {
    [CmdletBinding()]
    param()

    $rawEntries = @([string]$env:PATH -split ';')
    $entries = @($rawEntries | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $emptyEntries = @($rawEntries | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count

    $seen = @{}
    $duplicates = New-Object System.Collections.Generic.List[string]
    $missing = New-Object System.Collections.Generic.List[string]
    foreach ($entry in $entries) {
        $expanded = [Environment]::ExpandEnvironmentVariables($entry.Trim().Trim('"'))
        $key = $expanded.TrimEnd('\').ToLowerInvariant()
        if ($seen.ContainsKey($key)) {
            if (-not $duplicates.Contains($expanded)) {
                $duplicates.Add($expanded)
            }
        }
        else {
            $seen[$key] = $true
        }
        if (-not (Test-Path -LiteralPath $expanded -PathType Container) -and -not $missing.Contains($expanded)) {
            $missing.Add($expanded)
        }
    }

    $commandConflicts = @()
    foreach ($name in @('pwsh', 'codex', 'node', 'python', 'git')) {
        $paths = @(
            Get-Command -Name $name -All -ErrorAction SilentlyContinue |
                Where-Object { $_.CommandType -eq 'Application' -or $_.CommandType -eq 'ExternalScript' } |
                ForEach-Object { [string]$_.Source } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Sort-Object -Unique
        )
        $directories = @($paths | ForEach-Object { Split-Path -Parent $_ } | Sort-Object -Unique)
        if ($directories.Count -gt 1) {
            $commandConflicts += [pscustomobject][ordered]@{
                command = $name
                paths   = $paths
            }
        }
    }

    $pwshPaths = @(
        Get-Command -Name 'pwsh' -All -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandType -eq 'Application' -or $_.CommandType -eq 'ExternalScript' } |
            ForEach-Object { [string]$_.Source }
    )
    $pwshShimFirst = $false
    if ($pwshPaths.Count -gt 0) {
        $pwshShimFirst = ([System.IO.Path]::GetExtension($pwshPaths[0]) -in @('.cmd', '.bat'))
    }

    $issues = $duplicates.Count + $missing.Count + $commandConflicts.Count + $emptyEntries
    if ($pwshShimFirst) {
        $issues++
    }
    $status = 'PASS'
    $summary = 'PATH entries and command resolution look consistent'
    $recommendation = @()
    if ($issues -gt 0) {
        $status = 'WARN'
        $summary = 'PATH health issues or command conflicts were detected'
        $recommendation = @('Review duplicate, missing, and conflicting entries before making a narrow manual PATH change. This tool will not modify PATH.')
    }

    New-DoctorCheck -Id 'path.health' -Category 'PATH' -Status $status -Summary $summary `
        -Details ('Duplicates: {0}; missing directories: {1}; command conflicts: {2}; empty entries: {3}.' -f $duplicates.Count, $missing.Count, $commandConflicts.Count, $emptyEntries) `
        -Recommendation $recommendation -Evidence ([pscustomobject][ordered]@{
            entryCount       = $entries.Count
            duplicateEntries = @($duplicates | Select-Object -First 10)
            missingEntries   = @($missing | Select-Object -First 10)
            commandConflicts = $commandConflicts
            pwshShimFirst    = $pwshShimFirst
        })
}

function Test-Wsl {
    [CmdletBinding()]
    param()

    $wslCommand = Get-Command -Name 'wsl.exe' -ErrorAction SilentlyContinue
    if ($null -eq $wslCommand) {
        return New-DoctorCheck -Id 'windows.wsl' -Category 'Windows features' -Status 'INFO' `
            -Summary 'WSL is not detected' `
            -Details 'WSL is optional. Native Windows Codex can run in PowerShell without WSL.'
    }

    $statusResult = Invoke-DoctorProcess -FilePath $wslCommand.Source -Arguments @('--status') -TimeoutSeconds 10
    if ($statusResult.timedOut) {
        return New-DoctorCheck -Id 'windows.wsl' -Category 'Windows features' -Status 'UNKNOWN' `
            -Summary 'WSL status check timed out' -Details 'wsl.exe was found, but wsl --status did not complete.' `
            -Recommendation @('Run wsl.exe --status and wsl.exe --list --verbose manually. Share only distribution names, states, versions, and error text.')
    }
    if (-not $statusResult.started -or $statusResult.exitCode -ne 0) {
        return New-DoctorCheck -Id 'windows.wsl' -Category 'Windows features' -Status 'UNKNOWN' `
            -Summary 'WSL command exists but its status could not be determined' `
            -Details ('{0} {1}' -f $statusResult.stderr, $statusResult.exception).Trim() `
            -Recommendation @('Run wsl.exe --status and wsl.exe --list --verbose manually. WSL absence or no distributions is not a Codex failure unless you selected a WSL workflow.') `
            -Evidence ([pscustomobject][ordered]@{ resolvedPath = $wslCommand.Source; exitCode = $statusResult.exitCode })
    }

    $listResult = Invoke-DoctorProcess -FilePath $wslCommand.Source -Arguments @('--list', '--quiet') -TimeoutSeconds 10
    if ($listResult.timedOut -or -not $listResult.started) {
        return New-DoctorCheck -Id 'windows.wsl' -Category 'Windows features' -Status 'UNKNOWN' `
            -Summary 'WSL is available, but installed distributions could not be listed' `
            -Details ('{0} {1}' -f $listResult.stderr, $listResult.exception).Trim() `
            -Recommendation @('Run wsl.exe --list --verbose manually and share only the redacted result.')
    }

    $distributions = @($listResult.stdout -split '\r?\n' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $status = 'PASS'
    $summary = 'WSL is enabled with at least one installed distribution'
    if ($distributions.Count -eq 0) {
        $status = 'INFO'
        $summary = 'WSL is enabled but no installed distribution was detected'
    }

    New-DoctorCheck -Id 'windows.wsl' -Category 'Windows features' -Status $status -Summary $summary `
        -Details 'WSL is optional unless the user selected a WSL-based Codex workflow.' `
        -Evidence ([pscustomobject][ordered]@{
            resolvedPath     = $wslCommand.Source
            distributionCount = $distributions.Count
            distributions    = $distributions
            statusOutput     = $statusResult.stdout
        })
}

function Test-WindowsLongPath {
    [CmdletBinding()]
    param()

    try {
        $value = Get-ItemPropertyValue -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -ErrorAction Stop
        if ([int]$value -eq 1) {
            return New-DoctorCheck -Id 'windows.long-paths' -Category 'Windows features' -Status 'PASS' `
                -Summary 'Windows long path support is enabled' `
                -Details 'Individual applications must also opt in to long-path-aware behavior.' `
                -Evidence ([pscustomobject][ordered]@{ longPathsEnabled = 1 })
        }
        return New-DoctorCheck -Id 'windows.long-paths' -Category 'Windows features' -Status 'INFO' `
            -Summary 'Windows long path support is disabled' `
            -Details 'Deep repository paths may hit legacy path-length limits. This tool reports the setting but never changes the registry.' `
            -Recommendation @('If a real path-length error occurs, ask your administrator or review Microsoft long path guidance before changing policy.') `
            -Evidence ([pscustomobject][ordered]@{ longPathsEnabled = [int]$value })
    }
    catch {
        return New-DoctorCheck -Id 'windows.long-paths' -Category 'Windows features' -Status 'UNKNOWN' `
            -Summary 'Windows long path setting could not be read' -Details $_.Exception.Message `
            -Recommendation @('Read HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem\LongPathsEnabled manually; do not change it solely to make this check pass.')
    }
}
