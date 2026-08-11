Set-StrictMode -Version 2.0

function Test-DoctorDirectoryWrite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $probePath = $null
    $created = $false
    $deleted = $false
    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
            throw 'Directory does not exist.'
        }
        $probePath = Join-Path -Path $Path -ChildPath ('.codex-doctor-write-{0}.tmp' -f [guid]::NewGuid().ToString('N'))
        [System.IO.File]::WriteAllText($probePath, 'Codex Windows Doctor write probe')
        $created = Test-Path -LiteralPath $probePath -PathType Leaf
        if ($created) {
            Remove-Item -LiteralPath $probePath -Force -ErrorAction Stop
            $deleted = -not (Test-Path -LiteralPath $probePath)
        }
        [pscustomobject][ordered]@{
            path      = $Path
            writable  = ($created -and $deleted)
            cleanedUp = $deleted
            error     = ''
        }
    }
    catch {
        if ($null -ne $probePath -and (Test-Path -LiteralPath $probePath -PathType Leaf)) {
            try {
                Remove-Item -LiteralPath $probePath -Force -ErrorAction Stop
                $deleted = $true
            }
            catch {
                $deleted = $false
            }
        }
        [pscustomobject][ordered]@{
            path      = $Path
            writable  = $false
            cleanedUp = $deleted
            error     = $_.Exception.Message
        }
    }
}

function Test-CodexHome {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$CodexHomeOverride,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$DefaultPath
    )

    $codexHomeValue = $env:CODEX_HOME
    if ($PSBoundParameters.ContainsKey('CodexHomeOverride')) {
        $codexHomeValue = $CodexHomeOverride
    }
    if ([string]::IsNullOrWhiteSpace($DefaultPath)) {
        $DefaultPath = Join-Path -Path ([Environment]::GetFolderPath('UserProfile')) -ChildPath '.codex'
    }

    $configured = -not [string]::IsNullOrWhiteSpace($codexHomeValue)
    $selectedPath = $DefaultPath
    if ($configured) {
        $selectedPath = [Environment]::ExpandEnvironmentVariables($codexHomeValue)
    }

    try {
        $fullSelectedPath = [System.IO.Path]::GetFullPath($selectedPath)
        $fullDefaultPath = [System.IO.Path]::GetFullPath($DefaultPath)
    }
    catch {
        return New-DoctorCheck -Id 'codex.home' -Category 'Codex' -Status 'WARN' `
            -Summary 'CODEX_HOME contains an invalid path' -Details $_.Exception.Message `
            -Recommendation @('Set CODEX_HOME only to a valid absolute directory, or unset it to use the default .codex directory. Review the change manually; this tool will not modify it.') `
            -Evidence ([pscustomobject][ordered]@{ configured = $configured; selectedPath = $selectedPath; defaultPath = $DefaultPath })
    }

    $exists = Test-Path -LiteralPath $fullSelectedPath -PathType Container
    $defaultExists = Test-Path -LiteralPath $fullDefaultPath -PathType Container
    $isAbsolute = [System.IO.Path]::IsPathRooted($selectedPath)
    $conflict = $configured -and $defaultExists -and ($fullSelectedPath.TrimEnd('\') -ine $fullDefaultPath.TrimEnd('\'))
    $writeProbe = $null
    if ($exists) {
        $writeProbe = Test-DoctorDirectoryWrite -Path $fullSelectedPath
    }

    $evidence = [pscustomobject][ordered]@{
        configured            = $configured
        selectedPath          = $fullSelectedPath
        selectedPathExists    = $exists
        defaultPath           = $fullDefaultPath
        defaultPathExists     = $defaultExists
        configuredAndDefaultDiffer = $conflict
        writable              = $(if ($null -ne $writeProbe) { $writeProbe.writable } else { $null })
        writeProbeCleanedUp   = $(if ($null -ne $writeProbe) { $writeProbe.cleanedUp } else { $null })
    }

    if ($configured -and -not $isAbsolute) {
        return New-DoctorCheck -Id 'codex.home' -Category 'Codex' -Status 'WARN' `
            -Summary 'CODEX_HOME is not an absolute path' -Details 'Relative paths can resolve differently between shells and applications.' `
            -Recommendation @('Use a valid absolute path for CODEX_HOME or unset it to use the default directory.') -Evidence $evidence
    }
    if ($configured -and -not $exists) {
        return New-DoctorCheck -Id 'codex.home' -Category 'Codex' -Status 'WARN' `
            -Summary 'CODEX_HOME points to a directory that does not exist' `
            -Details 'The configured directory was not created or is not visible to this user.' `
            -Recommendation @('Verify the CODEX_HOME value and directory location. Do not post config.toml, auth.json, credentials, sessions, or history publicly.') `
            -Evidence $evidence
    }
    if (-not $configured -and -not $exists) {
        return New-DoctorCheck -Id 'codex.home' -Category 'Codex' -Status 'INFO' `
            -Summary 'CODEX_HOME is unset and the default .codex directory was not found' `
            -Details 'This can be normal before Codex has created local state.' -Evidence $evidence
    }
    if ($null -ne $writeProbe -and -not $writeProbe.writable) {
        return New-DoctorCheck -Id 'codex.home' -Category 'Codex' -Status 'FAIL' `
            -Summary 'Codex home directory is not writable' -Details $writeProbe.error `
            -Recommendation @('Review the selected directory permissions for the current user. Do not take ownership of WindowsApps or disclose credential files.') -Evidence $evidence
    }
    if ($conflict) {
        return New-DoctorCheck -Id 'codex.home' -Category 'Codex' -Status 'WARN' `
            -Summary 'CODEX_HOME differs from an existing default .codex directory' `
            -Details 'Different Codex clients or shells may use different state locations.' `
            -Recommendation @('Confirm which directory each Codex client uses. Share only redacted path metadata, never auth.json or credential contents.') -Evidence $evidence
    }

    return New-DoctorCheck -Id 'codex.home' -Category 'Codex' -Status 'PASS' `
        -Summary 'Codex home directory is accessible and writable' `
        -Details 'Only directory existence and a disposable write probe were checked; configuration and credential files were not read.' `
        -Evidence $evidence
}

function Test-WorkspaceAndTempWrite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$WorkspacePath
    )

    $workspaceProbe = Test-DoctorDirectoryWrite -Path $WorkspacePath
    $workspaceStatus = 'PASS'
    $workspaceSummary = 'Workspace is writable and the probe was cleaned up'
    $workspaceRecommendation = @()
    if (-not $workspaceProbe.writable) {
        $workspaceStatus = 'FAIL'
        $workspaceSummary = 'Workspace write probe failed'
        $workspaceRecommendation = @('Move to a workspace the current user can write, or review the directory permissions. The doctor will not change permissions.')
    }
    $workspaceCheck = New-DoctorCheck -Id 'filesystem.workspace-write' -Category 'Filesystem' `
        -Status $workspaceStatus -Summary $workspaceSummary -Details $workspaceProbe.error `
        -Recommendation $workspaceRecommendation -Evidence $workspaceProbe

    $tempPath = [System.IO.Path]::GetTempPath()
    $tempProbe = Test-DoctorDirectoryWrite -Path $tempPath
    $tempStatus = 'PASS'
    $tempSummary = 'Temporary directory is writable and the probe was cleaned up'
    $tempRecommendation = @()
    if (-not $tempProbe.writable) {
        $tempStatus = 'FAIL'
        $tempSummary = 'Temporary directory write probe failed'
        $tempRecommendation = @('Check the TEMP/TMP directory path and current-user permissions. This tool will not change environment variables.')
    }
    $tempCheck = New-DoctorCheck -Id 'filesystem.temp-write' -Category 'Filesystem' `
        -Status $tempStatus -Summary $tempSummary -Details $tempProbe.error `
        -Recommendation $tempRecommendation -Evidence $tempProbe

    return @($workspaceCheck, $tempCheck)
}
