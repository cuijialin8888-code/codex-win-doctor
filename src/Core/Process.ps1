Set-StrictMode -Version 2.0

function ConvertTo-DoctorQuotedArgument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Argument
    )

    if ($Argument -notmatch '[\s"]') {
        return $Argument
    }

    $escaped = [System.Text.RegularExpressions.Regex]::Replace($Argument, '(\\*)"', '$1$1\"')
    $escaped = [System.Text.RegularExpressions.Regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"{0}"' -f $escaped
}

function Invoke-DoctorProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]]$Arguments = @(),

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 60)]
        [int]$TimeoutSeconds = 10
    )

    $process = $null
    try {
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $extension = [System.IO.Path]::GetExtension($FilePath)
        $argumentText = (($Arguments | ForEach-Object { ConvertTo-DoctorQuotedArgument -Argument $_ }) -join ' ')

        if ($extension -ieq '.cmd' -or $extension -ieq '.bat') {
            $startInfo.FileName = $env:ComSpec
            $quotedFile = ConvertTo-DoctorQuotedArgument -Argument $FilePath
            $startInfo.Arguments = '/d /s /c "{0} {1}"' -f $quotedFile, $argumentText
        }
        else {
            $startInfo.FileName = $FilePath
            $startInfo.Arguments = $argumentText
        }

        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        $started = $process.Start()
        if (-not $started) {
            throw 'The process did not start.'
        }

        $standardOutput = $process.StandardOutput.ReadToEndAsync()
        $standardError = $process.StandardError.ReadToEndAsync()
        $completed = $process.WaitForExit($TimeoutSeconds * 1000)

        if (-not $completed) {
            try {
                $process.Kill()
            }
            catch {
                Write-Verbose ('Unable to stop timed-out process: {0}' -f $_.Exception.Message)
            }
            return [pscustomobject][ordered]@{
                started   = $true
                timedOut  = $true
                exitCode  = $null
                stdout    = ''
                stderr    = ''
                exception = ''
            }
        }

        $process.WaitForExit()
        [pscustomobject][ordered]@{
            started   = $true
            timedOut  = $false
            exitCode  = $process.ExitCode
            stdout    = $standardOutput.Result.Trim()
            stderr    = $standardError.Result.Trim()
            exception = ''
        }
    }
    catch {
        [pscustomobject][ordered]@{
            started   = $false
            timedOut  = $false
            exitCode  = $null
            stdout    = ''
            stderr    = ''
            exception = $_.Exception.Message
        }
    }
    finally {
        if ($null -ne $process) {
            $process.Dispose()
        }
    }
}

function Get-DoctorCommandProbe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]]$Arguments = @('--version'),

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 60)]
        [int]$TimeoutSeconds = 10,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]$DiscoveredCommands,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [scriptblock]$ProcessInvoker
    )

    if ($PSBoundParameters.ContainsKey('DiscoveredCommands')) {
        $resolvedCommands = @($DiscoveredCommands)
    }
    else {
        $resolvedCommands = @(
            Get-Command -Name $Name -All -ErrorAction SilentlyContinue |
                Where-Object { $_.CommandType -eq 'Application' -or $_.CommandType -eq 'ExternalScript' }
        )
    }

    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($command in $resolvedCommands) {
        $source = [string]$command.Source
        if ([string]::IsNullOrWhiteSpace($source) -and $command.PSObject.Properties['Path']) {
            $source = [string]$command.Path
        }
        if (-not [string]::IsNullOrWhiteSpace($source) -and -not $paths.Contains($source)) {
            $paths.Add($source)
        }
    }

    if ($paths.Count -eq 0) {
        return [pscustomobject][ordered]@{
            name           = $Name
            state          = 'NotFound'
            resolvedPath   = $null
            allPaths       = @()
            multiple       = $false
            executable     = $false
            exitCode       = $null
            stdout         = ''
            stderr         = ''
            exception      = ''
        }
    }

    if ($null -ne $ProcessInvoker) {
        $result = & $ProcessInvoker $paths[0] $Arguments $TimeoutSeconds
    }
    else {
        $result = Invoke-DoctorProcess -FilePath $paths[0] -Arguments $Arguments -TimeoutSeconds $TimeoutSeconds
    }

    $combinedError = '{0} {1}' -f $result.stderr, $result.exception
    $localizedAccessDenied = -join @(
        [char]0x62D2,
        [char]0x7EDD,
        [char]0x8BBF,
        [char]0x95EE
    )
    $accessDeniedPattern = '(?i)access\s+(is\s+)?denied|permission\s+denied|unauthorized|0x80070005|{0}' -f [regex]::Escape($localizedAccessDenied)
    $state = 'Failed'
    if ($result.timedOut) {
        $state = 'TimedOut'
    }
    elseif ($result.started -and $result.exitCode -eq 0) {
        $state = 'Passed'
    }
    elseif ($combinedError -match $accessDeniedPattern) {
        $state = 'AccessDenied'
    }

    [pscustomobject][ordered]@{
        name           = $Name
        state          = $state
        resolvedPath   = $paths[0]
        allPaths       = @($paths)
        multiple       = ($paths.Count -gt 1)
        executable     = ($state -eq 'Passed')
        exitCode       = $result.exitCode
        stdout         = $result.stdout
        stderr         = $result.stderr
        exception      = $result.exception
    }
}
