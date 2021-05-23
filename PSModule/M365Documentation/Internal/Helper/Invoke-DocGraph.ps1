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
        [string]$AcceptLanguage

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
        $header = @{Authorization = "Bearer $($script:token.AccessToken)"}
        if($AcceptLanguage){
            $header.Add("Accept-Language",$AcceptLanguage)
        }
        $value = Invoke-RestMethod -Headers $header -Uri  $FullUrl -Method Get -ErrorAction Stop
    } catch {
        
        if($_.Exception.Response.StatusCode -eq "Forbidden"){
            throw "Used application does not have sufficiant permission to access: $FullUrl"
        } else {
            Write-Error $_
        }
    }

    return $value
}