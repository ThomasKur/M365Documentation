Function Get-MdmConfigurationProfile(){
    <#
    .SYNOPSIS
    This function is used to get the all configuration profiles from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the configuration profiles
    .EXAMPLE
    Get-MdmConfigurationProfile
    Returns the configuration profiles configured in Intune
    .NOTES
    NAME: Get-MdmConfigurationProfile
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Device Configuration"
    $DocSec.Text = "This section contains a list of all device configuration profiles available in Intune."

    $ReturnObj = @()

    $Policies = Invoke-DocGraph -Path "/deviceManagement/deviceConfigurations" -Beta 
    foreach($Policy in $Policies.Value){
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