Function Get-AADDomain(){
    <#
    .SYNOPSIS
    This function is used to get the Domains from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Domains from Azure AD
    .EXAMPLE
    Get-AADDomain
    Returns the Domains defined in Azure AD.
    .NOTES
    NAME: Get-AADDomain
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Domains"
    $DocSec.Text = "Lists all domain associated with the tenant."
    $DocSec.Objects = (Invoke-DocGraph -Path "/domains").Value
    $DocSec.Transpose = $false
    if($null -eq $DocSec.Objects){
        return $null
    } else {
        return $DocSec
    }
    
}