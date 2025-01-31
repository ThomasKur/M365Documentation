function Test-TokenExpiration {
    [CmdLetBinding()]
    Param()

    If(-not($script:token)) {
        # It's unlikely we'd ever get here without having a token, but just in case.
        Throw "There is no token to refresh."
    }

    Write-Verbose "Current token expires $($script:token.ExpiresOn.LocalDateTime)"

    If($script:token.ForceRefresh -eq $False) {
        # User doesn't want the token refreshed. Let it fail naturally if the token expires.
        Return
    }

    # We give ourselves 1 minute of runway (way more than likely needed) to account for any time
    # between the functions being called and the request actually getting out to graph.

    if($script:token.ExpiresOn.LocalDateTime -gt $(Get-Date).AddMinutes(11)) {
        Return
    }

    if($script:tokenRequest.ClientSecret) {
        # Using PublicClient-Silent
        try {
            $script:token = Connect-M365Doc -ClientId $script:tokenRequest.ClientId -ClientSecret $script:tokenRequest.ClientSecret -TenantId $script:tokenRequest.TenantId
        } catch {
            Throw "Could not refresh token. $($_.Exception.Message)."
        }
    } elseif ($script:tokenRequest) {
        # Using Interactive
        try {
            $script:token = Connect-M365Doc -Force
        } catch {
            Throw "Could not refresh token. $($_.Exception.Message)."
        }
    } else {
        # Using a custom token. Cannot automatically refresh. Let it fail naturally if the token expires.
    }

}