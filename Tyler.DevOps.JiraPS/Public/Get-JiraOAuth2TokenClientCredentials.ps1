function Get-JiraOAuth2TokenClientCredentials {
    [CmdletBinding()]
    param(
        # Required
        [Parameter(Mandatory)]
        [string] $ClientId,

        [Parameter(Mandatory)]
        [string] $ClientSecret,

        [Parameter()]
        [string] $TokenEndpoint = "https://auth.atlassian.com/oauth/token",

        # Optional
        [string[]] $Scope = @("read:jira-work"),
        [string]   $Audience,        # e.g. api.atlassian.com (Okta/Atlassian style)
        [string]   $Resource,        # e.g. https://management.azure.com/ (AAD v1)
        [switch]   $SendCredsInBody, # Some IdPs require client_id/secret in form body instead of Authorization: Basic
        [switch]   $AsBearerHeader,  # Return @{ Authorization = "Bearer <token>" }
        [int]      $ExpirySkewSec = 60, # Refresh buffer
        [int]      $TimeoutSec   = 30
    )

    begin {
        # Simple in-session token cache keyed by request fingerprint
        if (-not $script:OAuth2TokenCache) { $script:OAuth2TokenCache = @{} }

        # Build a stable cache key
        $keyParts = @(
            $TokenEndpoint
            $ClientId
            ($Scope -join " ")
            $Audience
            $Resource
            [string]$SendCredsInBody
        )
        $cacheKey = ($keyParts -join '|')  # unique enough per combination
    }

    process {
        # Return cached if still valid
        if ($script:OAuth2TokenCache.ContainsKey($cacheKey)) {
            $cached = $script:OAuth2TokenCache[$cacheKey]
            $now    = [DateTimeOffset]::UtcNow
            if ($cached.expires_on -gt $now.AddSeconds($ExpirySkewSec)) {
                if ($AsBearerHeader) {
                    return @{ Authorization = "Bearer $($cached.access_token)" }
                } else {
                    return $cached
                }
            }
        }

        # Form body per RFC 6749
        $form = @{
            grant_type = 'client_credentials'
        }
        if ($Scope -and $Scope.Count -gt 0) { $form.scope = ($Scope -join ' ') }
        if ($Audience) { $form.audience = $Audience }
        if ($Resource) { $form.resource = $Resource }

        # Auth headers
        $headers = @{
            'Accept' = 'application/json'
        }
        if (-not $SendCredsInBody) {
            $basic = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$ClientId`:$ClientSecret"))
            $headers['Authorization'] = "Basic $basic"
        } else {
            $form.client_id     = $ClientId
            $form.client_secret = $ClientSecret
        }

        try {
            $response = Invoke-RestMethod -Method Post -Uri $TokenEndpoint `
                -Headers $headers -Body $form -ContentType 'application/x-www-form-urlencoded' `
                -TimeoutSec $TimeoutSec

            if (-not $response.access_token) {
                throw "No access_token in response. Raw: $(($response | ConvertTo-Json -Depth 6))"
            }

            # Normalize expiry
            $now = [DateTimeOffset]::UtcNow
            $expiresOn =
                if ($response.expires_in) {
                    $now.AddSeconds([int]$response.expires_in)
                } elseif ($response.expires_on) {
                    # Some providers return epoch seconds or an ISO timestamp
                    $eo = $response.expires_on.ToString()
                    if ($eo -match '^\d{10,}$') {
                        [DateTimeOffset]::FromUnixTimeSeconds([int64]$eo)
                    } else {
                        [DateTimeOffset]::Parse($eo)
                    }
                } else {
                    $now.AddMinutes(30) # sane default if missing
                }

            $tokenRecord = [pscustomobject]@{
                access_token = $response.access_token
                token_type   = $response.token_type
                scope        = $response.scope
                expires_in   = $response.expires_in
                expires_on   = $expiresOn
                raw          = $response
            }

            # Cache it
            $script:OAuth2TokenCache[$cacheKey] = $tokenRecord

            if ($AsBearerHeader) {
                return @{ Authorization = "Bearer $($tokenRecord.access_token)" }
            } else {
                return $tokenRecord
            }
        }
        catch {
            throw "Token request failed: $($_.Exception.Message)"
        }
    }
}
