Set-StrictMode -Version 2.0

function Get-DoctorFirstOutputLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ''
    }
    return (($Text -split '\r?\n')[0]).Trim()
}

function New-DoctorCommandCheck {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'Creates an in-memory check object and does not change system state.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [string]$DisplayName,

        [Parameter(Mandatory = $true)]
        [object]$Probe,

        [Parameter(Mandatory = $false)]
        [ValidateSet('PASS', 'WARN', 'FAIL', 'INFO', 'UNKNOWN')]
        [string]$AbsentStatus = 'INFO',

        [Parameter(Mandatory = $false)]
        [string]$AbsentDetails = 'This command is optional for some Codex workflows.',

        [Parameter(Mandatory = $false)]
        [string[]]$AbsentRecommendation = @(),

        [Parameter(Mandatory = $false)]
        [switch]$OptionalWhenBroken
    )

    $evidence = [pscustomobject][ordered]@{
        resolvedPath = $Probe.resolvedPath
        allPaths     = @($Probe.allPaths)
        execution    = $Probe.state
        exitCode     = $Probe.exitCode
        version      = Get-DoctorFirstOutputLine -Text $Probe.stdout
        error        = Get-DoctorFirstOutputLine -Text ('{0} {1}' -f $Probe.stderr, $Probe.exception)
    }

    if ($Probe.state -eq 'NotFound') {
        return New-DoctorCheck -Id $Id -Category $Category -Status $AbsentStatus `
            -Summary ('{0} not detected' -f $DisplayName) -Details $AbsentDetails `
            -Recommendation $AbsentRecommendation -Evidence $evidence
    }

    if ($Probe.state -eq 'Passed') {
        $status = 'PASS'
        $summary = '{0} is executable' -f $DisplayName
        $details = Get-DoctorFirstOutputLine -Text $Probe.stdout
        if ($Probe.multiple) {
            $status = 'WARN'
            $summary = 'Multiple {0} commands were detected' -f $DisplayName
            $details = 'Review the resolution order if behavior differs between terminals or applications.'
        }
        return New-DoctorCheck -Id $Id -Category $Category -Status $status `
            -Summary $summary -Details $details `
            -Recommendation $(if ($Probe.multiple) { @('Review the listed command paths and keep the intended installation first on PATH; this tool will not modify PATH.') } else { @() }) `
            -Evidence $evidence
    }

    $failureStatus = 'FAIL'
    if ($OptionalWhenBroken) {
        $failureStatus = 'WARN'
    }
    $summary = '{0} resolved but could not be executed' -f $DisplayName
    if ($Probe.state -eq 'AccessDenied') {
        $summary = '{0} resolved but is not executable (Access Denied)' -f $DisplayName
    }
    elseif ($Probe.state -eq 'TimedOut') {
        $summary = '{0} execution timed out' -f $DisplayName
    }

    New-DoctorCheck -Id $Id -Category $Category -Status $failureStatus -Summary $summary `
        -Details 'Command discovery succeeded, but the capability probe did not.' `
        -Recommendation @('Run the listed executable path with --version in the same shell and review file permissions or application alias conflicts. Do not change PATH until the resolved path is understood.') `
        -Evidence $evidence
}

function Test-PowerShellEnvironment {
    [CmdletBinding()]
    param()

    $checks = @()
    $shells = @(
        [pscustomobject]@{ Name = 'pwsh'; Id = 'shell.pwsh'; Display = 'PowerShell 7 (pwsh)'; Absent = 'INFO' },
        [pscustomobject]@{ Name = 'powershell'; Id = 'shell.windows-powershell'; Display = 'Windows PowerShell'; Absent = 'FAIL' }
    )

    foreach ($shell in $shells) {
        $arguments = @('-NoLogo', '-NoProfile', '-NonInteractive', '-Command', 'Write-Output __CODEX_DOCTOR_OK__; Write-Output $PSVersionTable.PSVersion.ToString()')
        $probe = Get-DoctorCommandProbe -Name $shell.Name -Arguments $arguments
        $check = New-DoctorCommandCheck -Id $shell.Id -Category 'PowerShell' -DisplayName $shell.Display `
            -Probe $probe -AbsentStatus $shell.Absent `
            -AbsentDetails $(if ($shell.Name -eq 'pwsh') { 'PowerShell 7 is preferred, but Windows PowerShell 5.1 is supported.' } else { 'Windows PowerShell is expected on supported Windows versions.' })

        if ($probe.state -eq 'Passed') {
            $firstExtension = [System.IO.Path]::GetExtension([string]$probe.resolvedPath)
            if ($firstExtension -in @('.cmd', '.bat')) {
                $check.status = 'WARN'
                $check.summary = '{0} resolves to a command shim' -f $shell.Display
                $check.details = 'A .cmd or .bat shim resolves before the native shell executable.'
                $check.recommendation = @('Inspect the listed resolution order. Prefer the intended pwsh.exe or powershell.exe path; this tool will not change PATH.')
            }
        }
        $checks += $check
    }

    return $checks
}

function Test-VersionControlTool {
    [CmdletBinding()]
    param()

    $gitProbe = Get-DoctorCommandProbe -Name 'git' -Arguments @('--version')
    $gitCheck = New-DoctorCommandCheck -Id 'tools.git' -Category 'Version control' -DisplayName 'Git' `
        -Probe $gitProbe -AbsentStatus 'WARN' -AbsentDetails 'Codex can run without Git, but repository workflows and the documented clone quick start need it.' `
        -AbsentRecommendation @('Install Git only if you need repository workflows, then open a new terminal and rerun the doctor.')

    $ghProbe = Get-DoctorCommandProbe -Name 'gh' -Arguments @('--version')
    $ghCheck = New-DoctorCommandCheck -Id 'tools.github-cli' -Category 'Version control' -DisplayName 'GitHub CLI' `
        -Probe $ghProbe -AbsentStatus 'INFO' -AbsentDetails 'GitHub CLI is optional and is not required to run Codex Windows Doctor.' `
        -OptionalWhenBroken

    return @($gitCheck, $ghCheck)
}

function Test-DeveloperDependency {
    [CmdletBinding()]
    param()

    $definitions = @(
        [pscustomobject]@{ Name = 'node'; Id = 'dependency.node'; Display = 'Node.js'; Arguments = @('--version') },
        [pscustomobject]@{ Name = 'npm'; Id = 'dependency.npm'; Display = 'npm'; Arguments = @('--version') },
        [pscustomobject]@{ Name = 'python'; Id = 'dependency.python'; Display = 'Python'; Arguments = @('--version') },
        [pscustomobject]@{ Name = 'py'; Id = 'dependency.py-launcher'; Display = 'Python launcher (py)'; Arguments = @('--version') },
        [pscustomobject]@{ Name = 'pip'; Id = 'dependency.pip'; Display = 'pip'; Arguments = @('--version') }
    )

    $checks = @()
    foreach ($definition in $definitions) {
        $probe = Get-DoctorCommandProbe -Name $definition.Name -Arguments $definition.Arguments
        $checks += New-DoctorCommandCheck -Id $definition.Id -Category 'Optional dependencies' `
            -DisplayName $definition.Display -Probe $probe -AbsentStatus 'INFO' `
            -AbsentDetails ('{0} is not a universal Codex requirement. Some repository workflows may require it.' -f $definition.Display) `
            -OptionalWhenBroken
    }
    return $checks
}

function Test-ArchiveTool {
    [CmdletBinding()]
    param()

    $unzipProbe = Get-DoctorCommandProbe -Name 'unzip' -Arguments @('-v')
    $tarProbe = Get-DoctorCommandProbe -Name 'tar' -Arguments @('--version')
    $expandCommand = Get-Command -Name 'Expand-Archive' -ErrorAction SilentlyContinue
    $expandAvailable = ($null -ne $expandCommand)
    $nativeAlternative = ($tarProbe.state -eq 'Passed' -or $expandAvailable)

    $unzipAbsentStatus = 'INFO'
    if (-not $nativeAlternative) {
        $unzipAbsentStatus = 'WARN'
    }
    $unzipCheck = New-DoctorCommandCheck -Id 'archive.unzip' -Category 'Archive tools' -DisplayName 'unzip' `
        -Probe $unzipProbe -AbsentStatus $unzipAbsentStatus `
        -AbsentDetails $(if ($nativeAlternative) { 'Unix unzip is absent, but a Windows-native ZIP capability is available.' } else { 'No tested ZIP extraction alternative was found.' }) `
        -AbsentRecommendation $(if ($nativeAlternative) { @() } else { @('Confirm that tar.exe or the Expand-Archive cmdlet is available. This tool will not install unzip.') }) `
        -OptionalWhenBroken

    $tarAbsentStatus = 'INFO'
    if (-not $expandAvailable -and $unzipProbe.state -ne 'Passed') {
        $tarAbsentStatus = 'WARN'
    }
    $tarCheck = New-DoctorCommandCheck -Id 'archive.tar' -Category 'Archive tools' -DisplayName 'tar.exe' `
        -Probe $tarProbe -AbsentStatus $tarAbsentStatus `
        -AbsentDetails 'tar.exe is a useful Windows-native archive capability; Expand-Archive may still provide ZIP extraction.' `
        -OptionalWhenBroken

    if ($expandAvailable) {
        $expandCheck = New-DoctorCheck -Id 'archive.expand-archive' -Category 'Archive tools' -Status 'PASS' `
            -Summary 'Expand-Archive is available' -Details 'Windows can extract ZIP files without a Unix unzip command.' `
            -Evidence ([pscustomobject][ordered]@{ commandType = [string]$expandCommand.CommandType; module = [string]$expandCommand.ModuleName })
    }
    else {
        $expandStatus = 'INFO'
        if ($tarProbe.state -ne 'Passed' -and $unzipProbe.state -ne 'Passed') {
            $expandStatus = 'WARN'
        }
        $expandCheck = New-DoctorCheck -Id 'archive.expand-archive' -Category 'Archive tools' -Status $expandStatus `
            -Summary 'Expand-Archive not detected' -Details 'Another archive tool may still be sufficient.' `
            -Recommendation $(if ($expandStatus -eq 'WARN') { @('Check whether the Microsoft.PowerShell.Archive module is available in this PowerShell installation.') } else { @() })
    }

    return @($unzipCheck, $tarCheck, $expandCheck)
}

function Test-Ripgrep {
    [CmdletBinding()]
    param()

    $probe = Get-DoctorCommandProbe -Name 'rg' -Arguments @('--version')
    New-DoctorCommandCheck -Id 'tools.ripgrep' -Category 'Developer tools' -DisplayName 'ripgrep (rg)' `
        -Probe $probe -AbsentStatus 'INFO' `
        -AbsentDetails 'ripgrep is useful for fast repository search, but its absence does not prove Codex is broken.'
}
