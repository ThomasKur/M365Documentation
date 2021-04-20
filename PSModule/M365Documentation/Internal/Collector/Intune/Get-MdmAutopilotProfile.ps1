Function Get-MdmAutopilotProfile(){
    <#
    .SYNOPSIS
    This function is used to get the all Autopilot Profile from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Autopilot Profile
    .EXAMPLE
    Get-MdmAutopilotProfile
    Returns the Autopilot Profile configured in Intune
    .NOTES
    NAME: Get-MdmAutopilotProfile
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Autopilot Profiles"
    $DocSec.Text = "This section contains a list of all Autopilot Profiles available in Intune."

    $ReturnObj = @()

    $Policies = Invoke-DocGraph -Path "/deviceManagement/windowsAutopilotDeploymentProfiles" -Beta 
    foreach($Policy in $Policies.Value){
        $PolicyA = (Invoke-DocGraph -Path "/deviceManagement/windowsAutopilotDeploymentProfiles/$($Policy.Id)/assignments" -Beta).value

        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $Policy.displayName
        $DocSecSingle.Text = $Policy.description
        $DocSecSingle.Objects = $Policy
        $DocSecSingle.Transpose = $true
        $DocSecSingle.SubSections = Get-AssignmentDetail -Assignments $PolicyA
        $ReturnObj += $DocSecSingle
    } 
    $DocSec.SubSections = $ReturnObj

    return $DocSec
}