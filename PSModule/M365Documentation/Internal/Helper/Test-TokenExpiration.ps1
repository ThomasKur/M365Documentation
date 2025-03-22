function Test-TokenExpiration {
    [CmdLetBinding()]
    Param()

    If(-not($script:token)) {
        # It's unlikely we'd ever get here without having a token, but just in case.
        Throw "There is no token to refresh."
    }

    Write-Verbose "Current token expires $($script:token.ExpiresOn.LocalDateTime)"

    If($script:token -and $script:token.ForceRefresh -eq $False) {
        # User doesn't want the token refreshed. Let it fail naturally if the token expires.
        Return
    }

    # We give ourselves 1 minute of runway (way more than likely needed) to account for any time
    # between the functions being called and the request actually getting out to graph.

    if($script:token -and $script:token.ExpiresOn.LocalDateTime -ge $(Get-Date).AddMinutes(-1)) {
        Return
    }

    if($script:token -and $script:tokenRequest.ClientSecret) {
        # Using PublicClient-Silent
        try {
            Connect-M365Doc -ClientId $script:tokenRequest.ClientId -ClientSecret $script:tokenRequest.ClientSecret -TenantId $script:tokenRequest.TenantId -Verbose
        } catch {
            Throw "Could not refresh token. $($_.Exception.Message)."
        }
    } elseif ($script:token -and $script:tokenRequest) {
        # Using Interactive
        try {
            Connect-M365Doc -Force
        } catch {
            Throw "Could not refresh token. $($_.Exception.Message)."
        }
    } else {
        # Using a custom token. Cannot automatically refresh. Let it fail naturally if the token expires.
    }

}