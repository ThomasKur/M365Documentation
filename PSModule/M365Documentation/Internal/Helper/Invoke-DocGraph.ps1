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

    try{

        Test-TokenExpiration
        $header = @{Authorization = "Bearer $($script:token.AccessToken)"}
        if($AcceptLanguage){ $header.Add("Accept-Language",$AcceptLanguage) }

        $value = Invoke-RestMethod -Headers $header -Uri $FullUrl -Method Get -ErrorAction Stop
        if($FollowNextLink -and -not [String]::IsNullOrEmpty($value.'@odata.nextLink')){
            $NextLink = $value.'@odata.nextLink'
            do{
                
                Test-TokenExpiration
                $header = @{Authorization = "Bearer $($script:token.AccessToken)"} # Need to recreate the header incase the bearer token changed on refresh.
                if($AcceptLanguage){ $header.Add("Accept-Language",$AcceptLanguage) }       
                
                $valueNext = Invoke-RestMethod -Headers $header -Uri $NextLink -Method Get -ErrorAction Stop
                $NextLink = $valueNext.'@odata.nextLink'
                $valueNext.value | ForEach-Object { $value.value += $_ }

            } until(-not $NextLink)
        }
    } catch {
        
        $caughtError = $_

        try {
            # See if there is a valid error message to return in the json
            $jsonResponse = $caughtError.ErrorDetails.Message | ConvertFrom-Json
        } catch {
            # There was no message or it wasn't formatted as json. Throw original error.
            $jsonResponse = @{}
        }

        if($caughtError.Exception.Response.StatusCode -eq "Forbidden"){
            throw "Used application does not have sufficiant permission to access: $FullUrl"
        } elseif ($caughtError.Exception.Response.StatusCode -eq "NotFound" -and $_.Exception.Response.ResponseUri -like "https://graph.microsoft.com/v1.0/groups*"){
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