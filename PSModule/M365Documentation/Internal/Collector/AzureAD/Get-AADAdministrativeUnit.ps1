Function Get-AADAdministrativeUnit(){
    <#
    .SYNOPSIS
    This function is used to get the Administrative Units from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Administrative Units
    .EXAMPLE
    Get-AADAdministrativeUnits
    Returns the Administrative units defined in Azure AD.
    .NOTES
    NAME: Get-AADAdministrativeUnit
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Administrative Units"
    $DocSec.Text = "An administrative unit provides a conceptual container for User and Group directory objects. Using administrative units, a company administrator can now delegate administrative responsibilities to manage the users and groups contained within or scoped to an administrative unit to a regional or departmental administrator."
    $DocSec.Objects = (Invoke-DocGraph -Path "/administrativeUnits" -Beta).Value
    $DocSec.Transpose = $false
    if($null -eq $DocSec.Objects){
        return $null
    } else {
        return $DocSec
    }
    
}