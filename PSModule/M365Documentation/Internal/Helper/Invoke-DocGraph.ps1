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

    Nico Schmidtbauer 26.03.2025
    Updated script to add retry behavior when Graph Api Returns Error 429 - This might happen on busy tenants

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
        Write-Verbose "Requesting: $FullUrl"
        Test-TokenExpiration
        $header = @{Authorization = "Bearer $($script:token.AccessToken)"}
        if($AcceptLanguage){ $header.Add("Accept-Language",$AcceptLanguage) }
        $header.Add("Accept","application/json")
        
        # Use try catch, to get a possible exception
        try {
            $value = Invoke-RestMethod -Headers $header -Uri $FullUrl -Method Get
        }
        catch {
            $value = $_
        }
        
        # If an exception occures, check if the status code is 429, if not, throw the exception, otherwise run in retry.
        if($value.Exception) {
            if([int]$value.Exception.Response.StatusCode -ne "429") {
                throw $value
            }
            else {
                $requestCounter = 1
                # While the exception occures and is 429, retry up to 10 times and write a warning.
                while([int]$value.Exception.Response.StatusCode -eq "429") {
                    $maxRequests = 10
                    Write-Warning -Message "Graph API is currently busy (Too many requests) - Retrying request ($requestCounter/$maxRequests)"
                    try {
                        $value = Invoke-RestMethod -Headers $header -Uri $FullUrl -Method Get
                    }
                    catch {
                        $value = $_
                    }
                    if($requestCounter -gt $maxRequests -and [int]$value.Exception.Response.StatusCode -eq "429") {
                        Write-Warning -Message "Graph API is currently busy (Too many requests) - Retrys limit exceeded"
                        throw $value
                    }
                    Start-Sleep -seconds 1
                }
                # Just making sure if the last call returned an exception again, throw it here.
                if([int]$value.Exception) {
                    throw $value
                }
            }
        }
        
        if($FollowNextLink -and -not [String]::IsNullOrEmpty($value.'@odata.nextLink')){
            $NextLink = $value.'@odata.nextLink'
            do{
                Test-TokenExpiration
                $header = @{Authorization = "Bearer $($script:token.AccessToken)"} # Need to recreate the header incase the bearer token changed on refresh.
                if($AcceptLanguage){ $header.Add("Accept-Language",$AcceptLanguage) }       
                $header.Add("Accept","application/json")
                
                # Same exception / retry handling as above, just for possible '@odata.nextLink'
                try {
                    $valueNext = Invoke-RestMethod -Headers $header -Uri $NextLink -Method Get
                }
                catch {
                    $valueNext = $_
                }
                
                if($valueNext.Exception) {
                    if([int]$valueNext.Exception.Response.StatusCode -ne "429") {
                        throw $valueNext
                    }
                    else {
                        $requestCounter = 1
                        while([int]$valueNext.Exception.Response.StatusCode -eq "429") {
                            $maxRequests = 10
                            Write-Warning -Message "Graph API is currently busy (Too many requests) - Retrying request ($requestCounter/$maxRequests)"
                            try {
                                $valueNext = Invoke-RestMethod -Headers $header -Uri $NextLink -Method Get
                            }
                            catch {
                                $valueNext = $_
                            }
                            if($requestCounter -gt $maxRequests -and [int]$valueNext.Exception.Response.StatusCode -eq "429") {
                                Write-Warning -Message "Graph API is currently busy (Too many requests) - Retrys limit exceeded"
                                throw $valueNext
                            }
                            Start-Sleep -seconds 1
                        }
                        if([int]$valueNext.Exception) {
                            throw $valueNext
                        }
                    }
                }
                
                $NextLink = $valueNext.'@odata.nextLink'
                $valueNext.value | ForEach-Object { $value.value += $_ }

            } until(-not $NextLink)
        }
    } catch {
        
        $caughtError = $_
        Write-Verbose "Error on requesting '$FullUrl'"
        try {
            # See if there is a valid error message to return in the json
            if($caughtError.ErrorDetails.Message) {
                $jsonResponse = $caughtError.ErrorDetails.Message | ConvertFrom-Json
            } else {
                $jsonResponse = @{}
            }
        } catch {
            # There was no message or it wasn't formatted as json. Throw original error.
            $jsonResponse = @{}
        }

        if($caughtError.Exception.Response.StatusCode -eq "Forbidden"){
            Write-Warning "Forbidden: Used application does not have sufficiant permission to access. FullUrl: '$FullUrl'" -WarningAction Continue
        } elseif ($caughtError.Exception.Response.StatusCode -eq "Unauthorized"){
            Write-Warning "Unauthorized: The most common cause is an invalid, missing, or expired access token in the HTTP request header. It might also be a missing license assignment. FullUrl: '$FullUrl'" -WarningAction Continue
        } elseif ($caughtError.Exception.Response.StatusCode -eq "NotFound" -and $_.Exception.Response.ResponseUri -like "https://graph.microsoft.com/v1.0/groups*"){
            Write-Verbose "NotFound: Some Profiles/Apps are assigned to groups which do no longer exist. They are not displayed in the output $($_.Exception.Response.ResponseUri). FullUrl: '$FullUrl'" 
        } elseif ($caughtError.Exception.Response.StatusCode -eq "NotFound" -and $_.Exception.Response.ResponseUri -like "https://graph.microsoft.com/v1.0/users*"){
            Write-Verbose "NotFound: Some Profiles/Apps are assigned to users which do no longer exist. They are not displayed in the output $($_.Exception.Response.ResponseUri). FullUrl: '$FullUrl'"
        }  elseif ($caughtError.Exception.Response.StatusCode -eq "NotFound"){
            Write-Warning "NotFound: The configuration or object might not exist in your tenant. FullUrl: '$FullUrl'"
            $value = [PSCustomObject]@{
                Status    = 'Not Found'
            }
        } else  {
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