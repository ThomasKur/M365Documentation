Function Get-MobileAppDetailed(){
    <#
    .SYNOPSIS
    This function is used to get the all mobile apps from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the mobile apps
    .EXAMPLE
    Get-MobileAppsBeta
    Returns the mobile apps configured in Intune
    .NOTES
    NAME: Get-MobileAppsBeta
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Mobile Apps Detailed"
    $DocSec.Text = "This section contains a per applications the detailed configuration without assignments which are already documented in the Mobile App section."

    
    $Apps = Invoke-DocGraph -Path "/deviceAppManagement/mobileApps" -Beta 
    
    $DocSec.Objects = $Apps.value
    $DocSec.Transpose = $true

    return $DocSec
}