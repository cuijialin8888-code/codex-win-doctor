Set-StrictMode -Version 2.0

function Invoke-DoctorCheckGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true)]
        [string]$FallbackId,

        [Parameter(Mandatory = $true)]
        [string]$FallbackCategory
    )

    try {
        return @(& $ScriptBlock)
    }
    catch {
        return @(
            New-DoctorCheck -Id $FallbackId -Category $FallbackCategory -Status 'UNKNOWN' `
                -Summary 'Check group could not complete' -Details $_.Exception.Message `
                -Recommendation @('Share the check id and redacted error text when requesting help.')
        )
    }
}

function Invoke-CodexDoctor {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSReviewUnusedParameter',
        'WorkspacePath',
        Justification = 'WorkspacePath is captured by the bounded filesystem check script block.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$WorkspacePath
    )

    $platform = Get-DoctorPlatformInfo
    $checks = @()
    $groups = @(
        [pscustomobject]@{ Id = 'windows.environment'; Category = 'Environment'; Action = { Test-WindowsEnvironment -Platform $platform } },
        [pscustomobject]@{ Id = 'powershell.execution-policy'; Category = 'PowerShell'; Action = { Test-PowerShellExecutionPolicy } },
        [pscustomobject]@{ Id = 'codex.cli'; Category = 'Codex'; Action = { Test-CodexCli } },
        [pscustomobject]@{ Id = 'codex.desktop'; Category = 'Codex'; Action = { Test-CodexDesktopPackage } },
        [pscustomobject]@{ Id = 'shell.environment'; Category = 'PowerShell'; Action = { Test-PowerShellEnvironment } },
        [pscustomobject]@{ Id = 'tools.version-control'; Category = 'Version control'; Action = { Test-VersionControlTool } },
        [pscustomobject]@{ Id = 'dependencies.optional'; Category = 'Optional dependencies'; Action = { Test-DeveloperDependency } },
        [pscustomobject]@{ Id = 'archive.tools'; Category = 'Archive tools'; Action = { Test-ArchiveTool } },
        [pscustomobject]@{ Id = 'tools.ripgrep'; Category = 'Developer tools'; Action = { Test-Ripgrep } },
        [pscustomobject]@{ Id = 'codex.home'; Category = 'Codex'; Action = { Test-CodexHome } },
        [pscustomobject]@{ Id = 'filesystem.write'; Category = 'Filesystem'; Action = { Test-WorkspaceAndTempWrite -WorkspacePath $WorkspacePath } },
        [pscustomobject]@{ Id = 'path.health'; Category = 'PATH'; Action = { Test-PathHealth } },
        [pscustomobject]@{ Id = 'windows.wsl'; Category = 'Windows features'; Action = { Test-Wsl } },
        [pscustomobject]@{ Id = 'windows.long-paths'; Category = 'Windows features'; Action = { Test-WindowsLongPath } }
    )

    foreach ($group in $groups) {
        Write-Verbose ('Running check group: {0}' -f $group.Id)
        $checks += Invoke-DoctorCheckGroup -ScriptBlock $group.Action -FallbackId $group.Id -FallbackCategory $group.Category
    }

    return New-DoctorReport -Platform $platform -Checks $checks
}
