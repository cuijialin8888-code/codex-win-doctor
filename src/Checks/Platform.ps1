Set-StrictMode -Version 2.0

function Get-DoctorPlatformInfo {
    [CmdletBinding()]
    param()

    $registryData = $null
    try {
        $registryData = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
    }
    catch {
        Write-Verbose ('Windows version registry read failed: {0}' -f $_.Exception.Message)
    }

    $build = [string][Environment]::OSVersion.Version.Build
    $displayVersion = ''
    $edition = ''
    $productName = ''
    if ($null -ne $registryData) {
        if ($registryData.PSObject.Properties['CurrentBuildNumber']) {
            $build = [string]$registryData.CurrentBuildNumber
        }
        if ($registryData.PSObject.Properties['DisplayVersion']) {
            $displayVersion = [string]$registryData.DisplayVersion
        }
        elseif ($registryData.PSObject.Properties['ReleaseId']) {
            $displayVersion = [string]$registryData.ReleaseId
        }
        if ($registryData.PSObject.Properties['EditionID']) {
            $edition = [string]$registryData.EditionID
        }
        if ($registryData.PSObject.Properties['ProductName']) {
            $productName = [string]$registryData.ProductName
        }
    }

    $windowsName = $productName
    $buildNumber = 0
    if ([int]::TryParse($build, [ref]$buildNumber)) {
        if ($buildNumber -ge 22000) {
            $windowsName = 'Windows 11'
        }
        elseif ($buildNumber -ge 10240) {
            $windowsName = 'Windows 10'
        }
    }
    if ([string]::IsNullOrWhiteSpace($windowsName)) {
        $windowsName = 'Windows'
    }

    $osArchitecture = $env:PROCESSOR_ARCHITECTURE
    try {
        $osArchitecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    }
    catch {
        if (-not [string]::IsNullOrWhiteSpace($env:PROCESSOR_ARCHITEW6432)) {
            $osArchitecture = $env:PROCESSOR_ARCHITEW6432
        }
    }

    $processArchitecture = 'x86'
    if ([Environment]::Is64BitProcess) {
        $processArchitecture = 'x64'
    }
    if ($env:PROCESSOR_ARCHITECTURE -match 'ARM') {
        $processArchitecture = $env:PROCESSOR_ARCHITECTURE
    }

    $powerShellExecutable = ''
    try {
        $powerShellExecutable = (Get-Process -Id $PID -ErrorAction Stop).Path
    }
    catch {
        $powerShellExecutable = Join-Path -Path $PSHOME -ChildPath 'powershell.exe'
        if ($PSVersionTable.PSEdition -eq 'Core') {
            $powerShellExecutable = Join-Path -Path $PSHOME -ChildPath 'pwsh.exe'
        }
    }

    [pscustomobject][ordered]@{
        windowsName           = $windowsName
        windowsEdition        = $edition
        windowsDisplayVersion = $displayVersion
        osBuild               = $build
        osArchitecture        = $osArchitecture
        processArchitecture   = $processArchitecture
        powerShellVersion     = $PSVersionTable.PSVersion.ToString()
        powerShellEdition     = [string]$PSVersionTable.PSEdition
        powerShellExecutable  = $powerShellExecutable
    }
}

function Test-WindowsEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Platform
    )

    $details = '{0} {1}, build {2}; OS architecture {3}; process architecture {4}; PowerShell {5} ({6}).' -f
        $Platform.windowsName,
        $Platform.windowsDisplayVersion,
        $Platform.osBuild,
        $Platform.osArchitecture,
        $Platform.processArchitecture,
        $Platform.powerShellVersion,
        $Platform.powerShellEdition

    New-DoctorCheck -Id 'windows.environment' -Category 'Environment' -Status 'PASS' `
        -Summary ('{0} build {1}' -f $Platform.windowsName, $Platform.osBuild) `
        -Details $details -Evidence $Platform
}

function Test-PowerShellExecutionPolicy {
    [CmdletBinding()]
    param()

    try {
        $effective = [string](Get-ExecutionPolicy -ErrorAction Stop)
        $scopes = @(
            Get-ExecutionPolicy -List -ErrorAction Stop |
                ForEach-Object {
                    [pscustomobject][ordered]@{
                        scope  = [string]$_.Scope
                        policy = [string]$_.ExecutionPolicy
                    }
                }
        )

        $status = 'INFO'
        $summary = 'Execution policy is {0}' -f $effective
        $recommendation = @()
        if ($effective -in @('Restricted', 'AllSigned')) {
            $status = 'WARN'
            $summary = 'Execution policy may block this unsigned script'
            $recommendation = @(
                'Review the script first. If policy is not managed by your organization, run it once with: powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\codex-doctor.ps1'
            )
        }

        return New-DoctorCheck -Id 'powershell.execution-policy' -Category 'PowerShell' -Status $status `
            -Summary $summary -Details 'Execution policy is reported only; this tool never changes it.' `
            -Recommendation $recommendation -Evidence ([pscustomobject][ordered]@{
                effective = $effective
                scopes    = $scopes
            })
    }
    catch {
        return New-DoctorCheck -Id 'powershell.execution-policy' -Category 'PowerShell' -Status 'UNKNOWN' `
            -Summary 'Execution policy could not be read' -Details $_.Exception.Message `
            -Recommendation @('Run Get-ExecutionPolicy -List in the same shell and share only the policy names and scopes.')
    }
}
