Function Get-W365UserSetting(){
    <#
    .SYNOPSIS
    This function is used to get the Windows 365 user settings profiles from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the user settings 
    .EXAMPLE
    Get-W365UserSetting
    Returns the user settings profiles defined in Windows 365.
    .NOTES
    NAME: Get-W365UserSetting
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "User settings"
    $DocSec.Text = "Lists all user settings profiles associated with the tenant."
    $DocSec.Objects = (Invoke-DocGraph -Path "/deviceManagement/virtualEndpoint/provisioningPolicies" -Beta).Value
    $DocSec.Transpose = $false
    if($null -eq $DocSec.Objects){
        return $null
    } else {
        return $DocSec
    }
    
}