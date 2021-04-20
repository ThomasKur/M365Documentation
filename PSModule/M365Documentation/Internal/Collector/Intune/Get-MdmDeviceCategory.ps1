Function Get-MdmDeviceCategory(){
    <#
    .SYNOPSIS
    This function is used to get the all device categories defined from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the device categories defined
    .EXAMPLE
    Get-MdmDeviceCategory
    Returns the device categories configured in Intune
    .NOTES
    NAME: Get-MdmDeviceCategory
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Device Categories"
    $DocSec.Text = "This section contains all device categories defined in Intune."

    $Policies = Invoke-DocGraph -Path "/deviceManagement/deviceCategories" -Beta 
    
    $DocSec.Objects = $Policies.Value
    $DocSec.Transpose = $false
    


    return $DocSec
}