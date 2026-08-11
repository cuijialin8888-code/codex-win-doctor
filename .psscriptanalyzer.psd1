@{
    IncludeDefaultRules = $true
    Severity = @('Error', 'Warning')
    Rules = @{
        PSUseCompatibleSyntax = @{
            Enable = $true
            TargetVersions = @('5.1')
        }
    }
}
