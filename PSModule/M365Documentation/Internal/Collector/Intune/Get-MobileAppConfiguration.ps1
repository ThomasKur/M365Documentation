Function Get-MobileAppConfiguration(){
    <#
    .SYNOPSIS
    This function is used to get the all mobile app configuration policies from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the mobile app configuration policies
    .EXAMPLE
    Get-MobileAppConfiguration
    Returns the mobile app configurations configured in Intune
    .NOTES
    NAME: Get-MobileAppConfiguration
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Mobile App Configuration"
    $DocSec.Text = "This section contains a list of all mobile applications configuration policies available in Intune."

    $ReturnObj = @()

    $Apps = Invoke-DocGraph -Path "/deviceAppManagement/managedAppPolicies" -Beta 
    foreach($App in ($Apps.Value | Where-Object { $_.'@odata.type' -like "*AppConfiguration" })){
        $AppA = (Invoke-DocGraph -Path "/deviceAppManagement/targetedManagedAppConfigurations/$($App.Id)/assignments" -Beta).value
        
        if($null -ne $App.customSettings){
            foreach($s in $App.customSettings){
                $App | Add-Member Noteproperty "Custom Setting - $($s.name)" $s.value
            }
        }
        $AssignedApps = (Invoke-DocGraph -Path "/deviceAppManagement/targetedManagedAppConfigurations/$($App.Id)/apps" -Beta).value
        $App | Add-Member Noteproperty "Targeted Apps" ($AssignedApps.id -join ", ")

        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $App.displayName
        $DocSecSingle.Text = $App.description
        $DocSecSingle.Objects = $App 
        $DocSecSingle.Transpose = $true
        $DocSecSingle.SubSections = Get-AssignmentDetail -Assignments $AppA
        $ReturnObj += $DocSecSingle
    } 
    $DocSec.SubSections = $ReturnObj

    return $DocSec
}