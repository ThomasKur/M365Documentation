Function Invoke-DocGraph(){
    <#
    .SYNOPSIS
    This function Requests information from Microsoft Graph
    .DESCRIPTION
    This function Requests information from Microsoft Graph and returns the value as Object[]
    .EXAMPLE
    Invoke-DocGraph -url ""
    Returns "Type"
    .NOTES
    NAME: Thomas Kurth 3.3.2021
    #>
    [OutputType('System.Object[]')]
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$true,ParameterSetName = "FullPath")]
        $FullUrl,

        [Parameter(Mandatory=$true,ParameterSetName = "Path")]
        [string]$Path,

        [Parameter(Mandatory=$false,ParameterSetName = "Path")]
        [string]$BaseUrl = "https://graph.microsoft.com/",

        [Parameter(Mandatory=$false,ParameterSetName = "Path")]
        [switch]$Beta,

        [Parameter(Mandatory=$false,ParameterSetName = "Path")]
        [string]$AcceptLanguage,

        [Parameter(Mandatory=$false,ParameterSetName = "Path")]
        [bool]$FollowNextLink =  $true

    )
    if($PSCmdlet.ParameterSetName -eq "Path"){
        if($Beta){
            $version = "beta"
        } else {
            $version = "v1.0"
        }
        $FullUrl = "$BaseUrl$version$Path"
    }

    # Make sure our token isn't about to expire before the request processes.
    if($script:token.ExpiresOn.LocalDateTime -le $(Get-Date).AddMinutes(-1)) {
        if($script:tokenRequest.ClientSecret) {
            # Using PublicClient-Silent
            try {
                $script:token = Connect-M365Doc -ClientId $script:tokenRequest.ClientId -ClientSecret $script:tokenRequest.ClientSecret -TenantId $script:tokenRequest.TenantId
            } catch {
                Throw "Could not refresh token. $($_.Exception.Message)."
            }
        } elseif ($script.tokenRequest) {
            # Using Interactive
            try {
                $script:token = Connect-M365Doc -Force
            } catch {
                Throw "Could not refresh token. $($_.Exception.Message)."
            }
        } else {
            # Using Custom Token.
            Throw "Custom token expiring. Please create a new token."
        }
    }

    Write-Verbose "Current token expires $($script:token.ExpiresOn.LocalDateTime)"

    try{
        $header = @{Authorization = "Bearer $($script:token.AccessToken)"}
        if($AcceptLanguage){
            $header.Add("Accept-Language",$AcceptLanguage)
        }
        $value = Invoke-RestMethod -Headers $header -Uri  $FullUrl -Method Get -ErrorAction Stop
        if($FollowNextLink -and -not [String]::IsNullOrEmpty($value.'@odata.nextLink')){
            $NextLink = $value.'@odata.nextLink'
            do{
                $valueNext = Invoke-RestMethod -Headers $header -Uri $NextLink -Method Get -ErrorAction Stop
                $NextLink = $valueNext.'@odata.nextLink'
                $valueNext.value | ForEach-Object { $value.value += $_ }
            } until(-not $NextLink)
        }
    } catch {
        
        try {
            # See if there is a valid error message to return in the json
            $jsonResponse = $caughtError.ErrorDetails.Message | ConvertFrom-Json
        } catch {
            # There was no message or it wasn't formatted as json. Throw original error.
            $jsonResponse = @{}
        }

        if($_.Exception.Response.StatusCode -eq "Forbidden"){
            throw "Used application does not have sufficiant permission to access: $FullUrl"
        } elseif ($_.Exception.Response.StatusCode -eq "NotFound" -and $_.Exception.Response.ResponseUri -like "https://graph.microsoft.com/v1.0/groups*"){
            Write-Debug "Some Profiles/Apps are assigned to groups which do no longer exist. They are not displayed in the output $($_.Exception.Response.ResponseUri)."
        }  else  {
            if($jsonResponse.ErrorDetails.Message) {
                # If there was an error we can display, show it.
                throw $jsonResponse.ErrorDetails.Message
            } Else {
                # No mesasge returned from Graph, return raw error.
                throw $_
            }
        }
    }

    return $value
}