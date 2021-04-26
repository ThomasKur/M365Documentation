Function Get-AADOrganization(){
    <#
    .SYNOPSIS
    This function is used to get the Organization details from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Organization details from Azure AD
    .EXAMPLE
    Get-AADOrganization
    Returns the Organization details defined in Azure AD.
    .NOTES
    NAME: Get-AADOrganization
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Organization"
    $DocSec.Text = "Lists all Organizational settings."
    $DocSec.Objects = (Invoke-DocGraph -Path "/organization").Value
    $DocSec.Transpose = $true

    if($null -eq $DocSec.Objects){
        return $null
    } else {
        return $DocSec
    }
    
}