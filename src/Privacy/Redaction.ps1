Set-StrictMode -Version 2.0

function Test-DoctorSensitiveName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Name
    )

    return ($Name -match '(?i)(api[_-]?key|access[_-]?token|refresh[_-]?token|(^|[_-])token($|[_-])|auth(orization)?|bearer|credential|cookie|password|secret|github_token|gh_token)')
}

function ConvertTo-DoctorSafeText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Text
    )

    if ($null -eq $Text) {
        return $null
    }

    $safe = $Text
    $authorizationBearerPattern = '(?i)(?<prefix>["'']?\bAuthorization["'']?\s*[:=]\s*["'']?)(?<scheme>Bearer)\s+(?<secret>[^\s"'';,}\]&]+)'
    $safe = [regex]::Replace($safe, $authorizationBearerPattern, {
            param($match)
            return '{0}{1} [REDACTED]' -f $match.Groups['prefix'].Value, $match.Groups['scheme'].Value
        })

    $safe = [regex]::Replace($safe, '(?i)\b(Bearer)\s+(?!\[REDACTED\])[^\s"'';,}\]&]+', '$1 [REDACTED]')

    $assignmentPattern = '(?i)(?<prefix>["'']?\b(?:OPENAI_API_KEY|GITHUB_TOKEN|GH_TOKEN|API_KEY|ACCESS_TOKEN|REFRESH_TOKEN|COOKIE|CREDENTIAL)["'']?\s*[:=]\s*["'']?)(?<secret>[^\s"'';,}\]&]+)'
    $safe = [regex]::Replace($safe, $assignmentPattern, {
            param($match)
            return '{0}[REDACTED]' -f $match.Groups['prefix'].Value
        })
    $safe = [regex]::Replace($safe, '(?i)([?&](?:api_key|access_token|refresh_token)=)[^&\s]+', '$1[REDACTED]')
    $safe = [regex]::Replace($safe, '\bsk-[A-Za-z0-9_-]{8,}\b', '[REDACTED_SECRET]')
    $safe = [regex]::Replace($safe, '\b[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b', '[REDACTED_JWT]')

    $userProfile = [Environment]::GetFolderPath('UserProfile')
    if (-not [string]::IsNullOrWhiteSpace($userProfile)) {
        $safe = $safe.Replace($userProfile, '%USERPROFILE%')
        $safe = [regex]::Replace($safe, [regex]::Escape($userProfile), '%USERPROFILE%', 'IgnoreCase')
    }
    $safe = [regex]::Replace($safe, '(?i)\b[A-Z]:\\Users\\[^\\\s]+', 'C:\Users\<USER>')

    return $safe
}

function ConvertTo-DoctorSafeData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [AllowNull()]
        [object]$InputObject
    )

    process {
        if ($null -eq $InputObject) {
            return $null
        }

        if ($InputObject -is [string]) {
            return ConvertTo-DoctorSafeText -Text $InputObject
        }

        if ($InputObject -is [datetime] -or $InputObject -is [datetimeoffset] -or
            $InputObject -is [bool] -or $InputObject -is [byte] -or
            $InputObject -is [int16] -or $InputObject -is [int32] -or
            $InputObject -is [int64] -or $InputObject -is [uint16] -or
            $InputObject -is [uint32] -or $InputObject -is [uint64] -or
            $InputObject -is [single] -or $InputObject -is [double] -or
            $InputObject -is [decimal]) {
            return $InputObject
        }

        if ($InputObject -is [System.Collections.IDictionary]) {
            $safeDictionary = [ordered]@{}
            foreach ($key in $InputObject.Keys) {
                $keyText = [string]$key
                if (Test-DoctorSensitiveName -Name $keyText) {
                    $safeDictionary[$keyText] = '[REDACTED]'
                }
                else {
                    $safeDictionary[$keyText] = ConvertTo-DoctorSafeData -InputObject $InputObject[$key]
                }
            }
            return [pscustomobject]$safeDictionary
        }

        if ($InputObject -is [System.Collections.IEnumerable]) {
            $items = @()
            foreach ($item in $InputObject) {
                $items += ,(ConvertTo-DoctorSafeData -InputObject $item)
            }
            return $items
        }

        $properties = @($InputObject.PSObject.Properties | Where-Object { $_.MemberType -match 'Property' })
        if ($properties.Count -gt 0) {
            $safeObject = [ordered]@{}
            foreach ($property in $properties) {
                if (Test-DoctorSensitiveName -Name $property.Name) {
                    $safeObject[$property.Name] = '[REDACTED]'
                }
                else {
                    $safeObject[$property.Name] = ConvertTo-DoctorSafeData -InputObject $property.Value
                }
            }
            return [pscustomobject]$safeObject
        }

        return ConvertTo-DoctorSafeText -Text ([string]$InputObject)
    }
}
