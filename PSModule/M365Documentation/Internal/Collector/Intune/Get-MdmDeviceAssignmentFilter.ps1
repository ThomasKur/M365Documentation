Function Get-MdmDeviceAssignmentFilter(){
    <#
    .SYNOPSIS
    This function is used to get the all device filters defined from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the device filters defined
    .EXAMPLE
    Get-MdmDeviceAssignmentFilter
    Returns the device filters configured in Intune
    .NOTES
    NAME: Get-MdmDeviceAssignmentFilter
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Device Filters"
    $DocSec.Text = "This section contains all device filters defined in Intune."

    $Policies = Invoke-DocGraph -Path "/deviceManagement/assignmentFilters" -Beta 
    
    $DocSec.Objects = $Policies.Value
    $DocSec.Transpose = $false
    


    return $DocSec
}