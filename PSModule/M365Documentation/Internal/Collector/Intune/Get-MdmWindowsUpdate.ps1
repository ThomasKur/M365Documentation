Function Get-MdmWindowsUpdate(){
    <#
    .SYNOPSIS
    This function is used to get the all Windows Update configuration profiles from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Windows Update configuration profiles
    .EXAMPLE
    Get-MdmWindowsUpdate
    Returns the Windows Update configuration profiles configured in Intune
    .NOTES
    NAME: Get-MdmWindowsUpdate
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Windows Update Configuration"
    $DocSec.Text = "This section contains a list of all Windows Update configuration profiles available in Intune."

    $ReturnObj = @()

    $Policies = Invoke-DocGraph -Path "/deviceManagement/deviceConfigurations" -Beta 
    foreach($Policy in ($Policies.Value | Where-Object { $_.'@odata.type' -eq "#microsoft.graph.windowsUpdateForBusinessConfiguration"})){
        $PolicyA = (Invoke-DocGraph -Path "/deviceManagement/deviceConfigurations/$($Policy.Id)/assignments" -Beta).value
        
        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $Policy.displayName
        $DocSecSingle.Text = $Policy.description
        $DocSecSingle.Objects = $Policy
        $DocSecSingle.Transpose = $true
        $DocSecSingle.SubSections = @()
        $DocSecSingle.SubSections += Get-AssignmentDetail -Assignments $PolicyA

        if($null -ne $Policy.omaSettings){
            $DocSecSingleOma = New-Object DocSection
            $DocSecSingleOma.Title = "Custom OMA-Uri"
            $DocSecSingleOma.Text = ""
            $DocSecSingleOma.Objects = $Policy.omaSettings
            $DocSecSingleOma.Transpose = $false
            $DocSecSingle.SubSections += $DocSecSingleOma
        }

        $ReturnObj += $DocSecSingle
    } 

    
    $DocSec.SubSections = $ReturnObj

    return $DocSec
}