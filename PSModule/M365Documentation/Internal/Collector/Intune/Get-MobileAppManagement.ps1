Function Get-MobileAppManagement(){
    <#
    .SYNOPSIS
    This function is used to get the all mobile app management policies from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the mobile app management policies
    .EXAMPLE
    Get-MobileAppManagement
    Returns the mobile app protections configured in Intune
    .NOTES
    NAME: Get-MobileAppManagement
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Mobile App Management"
    $DocSec.Text = "This section contains a list of all mobile applications management policies available in Intune."

    $ReturnObj = @()

    $Apps = Invoke-DocGraph -Path "/deviceAppManagement/managedAppPolicies" -Beta 
    foreach($App in ($Apps.Value | Where-Object { $_.'@odata.type' -notlike "*AppConfiguration" })){
        

        if($App.'@odata.type' -eq "#microsoft.graph.mdmWindowsInformationProtectionPolicy"){
            $App.protectedApps = $App.protectedApps.displayName -join ", "
        } 
        
        if($App.'@odata.type' -eq "#microsoft.graph.iosManagedAppProtection"){
            $AppA = (Invoke-DocGraph -Path "/deviceAppManagement/iosManagedAppProtections/$($App.Id)/assignments" -Beta).value
            $AssignedApps = (Invoke-DocGraph -Path "/deviceAppManagement/iosManagedAppProtections/$($App.Id)/apps" -Beta).value
            $App | Add-Member Noteproperty "Targeted Apps" ($AssignedApps.id -join ", ")
        }
        if($App.'@odata.type' -eq "#microsoft.graph.androidManagedAppProtection"){
            $AppA = (Invoke-DocGraph -Path "/deviceAppManagement/androidManagedAppProtections/$($App.Id)/assignments" -Beta).value
            $AssignedApps = (Invoke-DocGraph -Path "/deviceAppManagement/androidManagedAppProtections/$($App.Id)/apps" -Beta).value
            $App | Add-Member Noteproperty "Targeted Apps" ($AssignedApps.id -join ", ")
        }
        if($App.'@odata.type' -eq "#microsoft.graph.mdmWindowsInformationProtectionPolicy"){
            $AppA = (Invoke-DocGraph -Path "/deviceAppManagement/mdmWindowsInformationProtectionPolicies/$($App.Id)/assignments" -Beta).value
        }
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