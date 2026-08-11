BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'TestBootstrap.ps1')
}

Describe 'Command discovery and capability probing' {
    It 'recognizes a command that exists and executes' {
        $successInvoker = {
            [pscustomobject]@{ started = $true; timedOut = $false; exitCode = 0; stdout = 'fake 1.0.0'; stderr = ''; exception = '' }
        }
        $commands = @([pscustomobject]@{ Source = 'C:\Tools\fake.exe' })
        $probe = Get-DoctorCommandProbe -Name 'fake' -DiscoveredCommands $commands -ProcessInvoker $successInvoker

        $probe.state | Should -Be 'Passed'
        $probe.executable | Should -BeTrue
    }

    It 'recognizes a command that does not exist' {
        $successInvoker = {
            [pscustomobject]@{ started = $true; timedOut = $false; exitCode = 0; stdout = 'fake 1.0.0'; stderr = ''; exception = '' }
        }
        $probe = Get-DoctorCommandProbe -Name 'missing' -DiscoveredCommands @() -ProcessInvoker $successInvoker

        $probe.state | Should -Be 'NotFound'
        $probe.executable | Should -BeFalse
    }

    It 'distinguishes resolved but not executable from not found' {
        $accessDeniedInvoker = {
            [pscustomobject]@{ started = $false; timedOut = $false; exitCode = $null; stdout = ''; stderr = ''; exception = 'Access is denied' }
        }
        $commands = @([pscustomobject]@{ Source = 'C:\Tools\blocked.exe' })
        $probe = Get-DoctorCommandProbe -Name 'blocked' -DiscoveredCommands $commands -ProcessInvoker $accessDeniedInvoker

        $probe.state | Should -Be 'AccessDenied'
        $probe.resolvedPath | Should -Be 'C:\Tools\blocked.exe'
        $probe.executable | Should -BeFalse
    }

    It 'preserves the resolution order for multiple commands' {
        $successInvoker = {
            [pscustomobject]@{ started = $true; timedOut = $false; exitCode = 0; stdout = 'fake 1.0.0'; stderr = ''; exception = '' }
        }
        $commands = @(
            [pscustomobject]@{ Source = 'C:\First\fake.exe' },
            [pscustomobject]@{ Source = 'C:\Second\fake.exe' }
        )
        $probe = Get-DoctorCommandProbe -Name 'fake' -DiscoveredCommands $commands -ProcessInvoker $successInvoker

        $probe.multiple | Should -BeTrue
        $probe.allPaths[0] | Should -Be 'C:\First\fake.exe'
        $probe.allPaths[1] | Should -Be 'C:\Second\fake.exe'
    }
}
