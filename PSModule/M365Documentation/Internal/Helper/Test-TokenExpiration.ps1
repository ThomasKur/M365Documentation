function Test-TokenExpiration {
    [CmdLetBinding()]
    Param()

    Write-Verbose "Current token expires $($script:token.ExpiresOn.LocalDateTime)"

    If(-not($script:tokenNextMessage)) {
        $script:tokenNextMessage = Get-Date
    }

    If($script:tokenNextMessage -le (Get-Date)) {
        Write-Host "$(Get-Date -format 'yyyy-MM-dd HH:mm:ss') The current token expiration date is $($script:token.ExpiresOn.LocalDateTime)." -ForegroundColor Cyan
        $script:tokenNextMessage = (Get-Date).AddMinutes(5)
    }

    If($script:token -and $script:token.ForceRefresh -eq $False) {
        # User doesn't want the token refreshed. Let it fail naturally if the token expires.
        Write-Host "$(Get-Date -format 'yyyy-MM-dd HH:mm:ss') Force Refresh is False. Not renewing token." -ForegroundColor Cyan
        Return
    }

    # We give ourselves 1 minute of runway (way more than likely needed) to account for any time
    # between the functions being called and the request actually getting out to graph.

    # **** BELOW FIX NEEDS TO STAY - INCLUDE IN COMMIT AND REMOVE THIS COMMENT
    if($script:token -and $script:token.ExpiresOn.LocalDateTime -ge $(Get-Date).AddMinutes(-1)) {
        Return
    }

    if($script:token -and $script:tokenRequest.ClientSecret) {
        # Using PublicClient-Silent
        try {
            Write-Host "$(Get-Date -format 'yyyy-MM-dd HH:mm:ss') Requesting a new token (PublicClient-Silent)." -ForegroundColor Cyan
            Write-Host "$(Get-Date -format 'yyyy-MM-dd HH:mm:ss') ClientId = $($script:tokenRequest.ClientId), TenantId = $($script:tokenRequest.TenantId)" -ForegroundColor Cyan
            Connect-M365Doc -ClientId $script:tokenRequest.ClientId -ClientSecret $script:tokenRequest.ClientSecret -TenantId $script:tokenRequest.TenantId -Verbose
        } catch {
            Throw "Could not refresh token. $($_.Exception.Message)."
        }
    } elseif ($script:token -and $script:tokenRequest) {
        # Using Interactive
        try {
            Write-Host "$(Get-Date -format 'yyyy-MM-dd HH:mm:ss') Requesting a new token (Interactive)." -ForegroundColor Cyan
            Connect-M365Doc -Force
        } catch {
            Throw "Could not refresh token. $($_.Exception.Message)."
        }
    } else {
        Write-Host "$(Get-Date -format 'yyyy-MM-dd HH:mm:ss') Custom Token, no refresh." -ForegroundColor Cyan
        # Using a custom token. Cannot automatically refresh. Let it fail naturally if the token expires.
    }

}