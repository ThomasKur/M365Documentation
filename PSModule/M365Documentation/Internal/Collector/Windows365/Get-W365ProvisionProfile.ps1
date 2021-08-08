Function Get-W365ProvisionProfile(){
    <#
    .SYNOPSIS
    This function is used to get the Windows 365 provision profiles from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the provisioning proviles
    .EXAMPLE
    Get-W365ProvisionProfile
    Returns the provision profiles defined in Windows 365.
    .NOTES
    NAME: Get-W365ProvisionProfile
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Provisioning profiles"
    $DocSec.Text = "Lists all provisioning profiles associated with the tenant."
    $DocSec.Objects = (Invoke-DocGraph -Path "/deviceManagement/virtualEndpoint/provisioningPolicies" -Beta).Value
    $DocSec.Transpose = $false
    if($null -eq $DocSec.Objects){
        return $null
    } else {
        return $DocSec
    }
    
}