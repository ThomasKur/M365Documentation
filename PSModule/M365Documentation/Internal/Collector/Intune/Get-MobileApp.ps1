Function Get-MobileApp(){
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

    $DocSec.Title = "Mobile Apps"
    $DocSec.Text = "This section contains a list of all applications available in Intune."

    $Intune_Apps = @()
    $AppGroups = @()
    $Apps = Invoke-DocGraph -Path "/deviceAppManagement/mobileApps" -Beta 
    foreach($App in $Apps.Value){
        $App_Assignment = Invoke-DocGraph -Path "/deviceAppManagement/mobileApps/$($App.id)/assignments" -Beta 
        if($App_Assignment.value){
            $Intune_App = New-Object -Type PSObject
            $Intune_App | Add-Member Noteproperty "Publisher" $App.publisher
            $Intune_App | Add-Member Noteproperty "DisplayName" $App.displayName
            $Intune_App | Add-Member Noteproperty "Type" (Format-MsGraphData $App.'@odata.type')
            $Assignments = @()
            foreach($Assignment in $App_Assignment.value) {
                if($null -ne $Assignment.target.groupId){
                    $Group = Invoke-DocGraph -Path "/groups/$($Assignment.target.groupId)"
                    $GroupName = $Group.displayName
                    $AppGroups += $Group
                    $Assignments += "$($GroupName)`n - Intent:$($Assignment.intent)"
                } else {
                    $Assignments += "$(($Assignment.target.'@odata.type' -replace "#microsoft.graph.",''))`n - Intent:$($Assignment.intent)"
                }
            }
            $Intune_App | Add-Member Noteproperty "Assignments" ($Assignments -join "`n")
            $Intune_Apps += $Intune_App
        }
    } 
    $DocSec.Objects = $Intune_Apps | Sort-Object Publisher,DisplayName
    $DocSec.Transpose = $false
    if(-not $AppGroups){
        $DocSec2 = New-Object DocSection
        $DocSec2.Title = "Groups used to assign apps"
        $DocSec2.Text = $null
        $DocSec2.Objects = Get-GroupInfo -Groups $AppGroups
        $DocSec2.Transpose = $false
        $DocSec.SubSections = @($DocSec2)
    }

    return $DocSec
}