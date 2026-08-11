BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'TestBootstrap.ps1')
}

$redactionCases = @(
    @{ Name = 'Authorization header'; Text = 'Authorization: Bearer abc123SECRET'; Secret = 'abc123SECRET'; Context = 'Authorization:\s*Bearer\s+\[REDACTED\]' }
    @{ Name = 'lowercase authorization header'; Text = 'authorization: bearer abc123SECRET'; Secret = 'abc123SECRET'; Context = 'authorization:\s*bearer\s+\[REDACTED\]' }
    @{ Name = 'uppercase authorization header'; Text = 'AUTHORIZATION: BEARER abc123SECRET'; Secret = 'abc123SECRET'; Context = 'AUTHORIZATION:\s*BEARER\s+\[REDACTED\]' }
    @{ Name = 'authorization header with extra spaces'; Text = 'Authorization:    Bearer    abc123SECRET'; Secret = 'abc123SECRET'; Context = 'Authorization:\s+Bearer\s+\[REDACTED\]' }
    @{ Name = 'authorization header without delimiter space'; Text = 'Authorization:Bearer abc123SECRET'; Secret = 'abc123SECRET'; Context = 'Authorization:Bearer\s+\[REDACTED\]' }
    @{ Name = 'standalone bearer credential'; Text = 'Bearer abc123SECRET'; Secret = 'abc123SECRET'; Context = 'Bearer\s+\[REDACTED\]' }
    @{ Name = 'JSON authorization header'; Text = '"Authorization": "Bearer abc123SECRET"'; Secret = 'abc123SECRET'; Context = '"Authorization":\s*"Bearer\s+\[REDACTED\]"' }
    @{ Name = 'authorization assignment'; Text = 'Authorization=Bearer abc123SECRET'; Secret = 'abc123SECRET'; Context = 'Authorization=Bearer\s+\[REDACTED\]' }
    @{ Name = 'OpenAI API key'; Text = 'OPENAI_API_KEY=sk-test-THIS_IS_NOT_REAL'; Secret = 'sk-test-THIS_IS_NOT_REAL'; Context = 'OPENAI_API_KEY=\[REDACTED\]' }
    @{ Name = 'GitHub classic token'; Text = 'GITHUB_TOKEN=ghp_FAKE_TOKEN_123456789'; Secret = 'ghp_FAKE_TOKEN_123456789'; Context = 'GITHUB_TOKEN=\[REDACTED\]' }
    @{ Name = 'GitHub fine-grained token'; Text = 'GH_TOKEN=github_pat_FAKE_TOKEN_123456789'; Secret = 'github_pat_FAKE_TOKEN_123456789'; Context = 'GH_TOKEN=\[REDACTED\]' }
    @{ Name = 'access token'; Text = 'access_token=FAKE_ACCESS_TOKEN_SECRET'; Secret = 'FAKE_ACCESS_TOKEN_SECRET'; Context = 'access_token=\[REDACTED\]' }
    @{ Name = 'refresh token'; Text = 'refresh_token=FAKE_REFRESH_TOKEN_SECRET'; Secret = 'FAKE_REFRESH_TOKEN_SECRET'; Context = 'refresh_token=\[REDACTED\]' }
)

Describe 'Privacy redaction' {
    It 'redacts <Name> without losing useful context' -ForEach $redactionCases {
        $safe = ConvertTo-DoctorSafeText -Text $Text

        $safe | Should -Not -Match ([regex]::Escape($Secret))
        $safe | Should -Match $Context
    }

    It 'redacts values based on sensitive property names' {
        $inputData = [pscustomobject]@{
            status       = 'PASS'
            access_token = 'fake-sensitive-value'
        }
        $safe = ConvertTo-DoctorSafeData -InputObject $inputData

        $safe.status | Should -Be 'PASS'
        $safe.access_token | Should -Be '[REDACTED]'
    }

    It 'does not over-redact ordinary diagnostic evidence' {
        $ordinary = 'Windows 11; PowerShell 7.6.4; codex-cli 0.1.0; C:\work\repo; commit 0123456789abcdef0123456789abcdef01234567; package 26.803.10989.0'

        (ConvertTo-DoctorSafeText -Text $ordinary) | Should -Be $ordinary
    }
}
