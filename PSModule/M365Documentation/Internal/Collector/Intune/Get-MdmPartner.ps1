Function Get-MdmPartner(){
    <#
    .SYNOPSIS
    This function is used to get the all device management partners defined from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the device management partners defined
    .EXAMPLE
    Get-MdmPartner
    Returns the device management partners configured in Intune
    .NOTES
    NAME: Get-MdmPartner
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Device Management Partners"
    $DocSec.Text = "This section contains all device management partners defined in Intune."

    $ReturnObj = @()

    $Partners = Invoke-DocGraph -Path "/deviceManagement/deviceManagementPartners"
    foreach($Partner in $Partners.Value){
        
        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $Partner.displayName
        $DocSecSingle.Text = $Partner.description
        $DocSecSingle.Objects = $Partner
        $DocSecSingle.Transpose = $true
        $ReturnObj += $DocSecSingle
    } 
    $DocSec.SubSections = $ReturnObj


    return $DocSec
}