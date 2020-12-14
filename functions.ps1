
# Exponential back off, up to a point
$script:backOffSeconds = 0
function Calculate-BackOff () {
    if ($script:backOffSeconds -gt 0) {
        $script:backOffSeconds = (2 * $script:backOffSeconds)
    } else {
        $script:backOffSeconds = 1
    }
    if ($script:backOffSeconds -gt 3600) { # 1 hour
        $script:backOffSeconds = 3600
    }

    Write-Debug "Calculate-BackOff: $script:backOffSeconds"
}
function Continue-BackOff {
    return ($script:backOffSeconds -gt 0)
}
function Get-BackOff {
    Write-Debug "Get-BackOff: $script:backOffSeconds"
    return $script:backOffSeconds
}
function Reset-BackOff () {
    $script:backOffSeconds = 0
}
function Wait-BackOff () {
    if ($script:backOffSeconds -gt 0) {
        Write-Host "Backing off and waiting $script:backOffSeconds seconds (until $((Get-Date).AddSeconds($script:backOffSeconds).ToString("HH:mm:ss")))..."
        Start-Sleep -Seconds $script:backOffSeconds
    }
}

function Display-ExceptionInformation() {
    Write-Verbose "$($_.Exception.GetType()): $($_.Exception.Message)"
    if ($_.ErrorDetails.Message) {
        Write-Debug $_.ErrorDetails.Message

        if ($_.ErrorDetails.Message -match "^{") {
            $errorResponse = ($_.ErrorDetails.Message | ConvertFrom-Json)
            $errorResult = $errorResponse.error 
            #$errorReason = $errorResult.errors[0].reason
            $errorCode = $errorResult.code
            $errorMessage = $errorResult.message
            Write-Verbose "${errorCode} - ${errorMessage}"
            Write-Verbose ($errorResult.errors | Format-Table | Out-String)    
            Write-Warning ($errorResult.message -replace "<[^<]*>","") # Remove markup
        }
    } else {
        Write-Warning $_.Exception.Message
    }
}

$script:googleToken = $null
function Get-GoogleToken (
    [string]$CredentialFile
) {
    Write-Debug "Get-GoogleToken $CredentialFile"
    if (!$script:googleToken -or ($(Get-Date) -ge $script:tokenExpireTime)) {
        if (!$CredentialFile -or !(Test-Path $CredentialFile)) {
            $CredentialFile = "./client_credentials.json"
            if (!(Test-Path $CredentialFile)) {
                Write-Warning "$CredentialFile not found. Download OAuth 2.0 Client Credential. See: https://cloud.google.com/docs/authentication/production"
                exit
            }
        }
    
        if (Get-Command gcloud -ErrorAction SilentlyContinue) {
            # Obtain token with Google Cloud SDK (automatically opens browser)
            $script:googleToken = $(gcloud auth application-default print-access-token 2>&1)
            if (!$script:googleToken) {
                Write-Debug "gcloud auth application-default login --client-id-file=$CredentialFile --scopes https://www.googleapis.com/auth/youtube.force-ssl"
                gcloud auth application-default login --client-id-file=$CredentialFile --scopes https://www.googleapis.com/auth/youtube.force-ssl | Out-Host
                $script:googleToken = $(gcloud auth application-default print-access-token 2>&1)
            }
            $tokenError = ($script:googleToken -match "ERROR:")
            Write-Verbose "tokenError: $tokenError"
            if ($tokenError) {
                $tokenError = ($tokenError -replace "ERROR: *","")
                throw $tokenError
            }
        } else {
            # Obtain token with oauth2l (open browser manually)
            Write-Debug "oauth2l fetch --credentials $CredentialFile --scope youtube.force-ssl"
            # oauth2l fetch --credentials $CredentialFile --scope youtube.force-ssl | Tee-Object -variable authresult | Out-Host
            oauth2l fetch --credentials $CredentialFile --scope youtube.force-ssl | Out-Host
            $authresult = $(oauth2l fetch  --credentials $CredentialFile --scope youtube.force-ssl)
            Write-Debug "authresult: $authresult"
            if ($authresult -match "ya29.*$") {
                Write-Debug "match: $($matches[0])"
                $script:googleToken = $matches[0]
            }
        }

        if ($script:googleToken) {
            Write-Debug "googleToken: $script:googleToken"
            if (Get-Command oauth2l -ErrorAction SilentlyContinue) {
                if ($DebugPreference -ieq "Continue") {
                    Write-Debug "$(oauth2l info --token $script:googleToken)"
                }
                $oauthinfo = (oauth2l info --token $script:googleToken | ConvertFrom-Json)
                if ($oauthinfo.expires_in) {
                    $script:tokenExpireTime = (Get-Date).AddSeconds($oauthinfo.expires_in)
                    Write-Verbose "OAuth token expires $($tokenExpireTime.ToString("HH:mm")), after which login may be required again"
                }
            }
        } else {
            Write-Warning "Could not obtain token for $CredentialFile"
        }
    }

    Write-Debug "Get-GoogleToken: $script:googleToken"
    return $script:googleToken
}

function Validate-Packages () {
    Write-Debug "Validate-Packages"
    if (Get-Command gcloud -ErrorAction SilentlyContinue) {
        Write-Verbose "Found gcloud"
    } else {
        if ($env:CLOUDSDK_ROOT_DIR) {
            $googleSDKBinDirectory=(Join-Path $env:CLOUDSDK_ROOT_DIR "bin")
        }
        if (!$googleSDKBinDirectory -and (Get-Command brew -ErrorAction SilentlyContinue)) {
            $googleSDKBinDirectory="$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin"
        }
        if (!$googleSDKBinDirectory) {
            Write-Warning "Google Cloud SDK not found. Run 'brew bundle', or get it here: https://cloud.google.com/sdk/docs/install"
        } else {
            Write-Verbose "Using Google Cloud SDK at $googleSDKBinDirectory"
            # Set up path to gcloud
            $env:PATH += ":${googleSDKBinDirectory}"
        }
        if (!(Get-Command gcloud -ErrorAction SilentlyContinue)) {
            # Still couldn't find gcloud CLI
            if (Get-Command oauth2l -ErrorAction SilentlyContinue) {
                Write-Verbose "Found oauth2l"
            } else {
                Write-Warning "oauth2l not found. Run 'brew bundle' (on macOS), or get it here: https://github.com/google/oauth2l"
                exit
            }
        }
    }
}