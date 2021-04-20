Function Get-MdmEnrollmentConfiguration(){
    <#
    .SYNOPSIS
    This function is used to get the all compliance policies from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the compliances policies
    .EXAMPLE
    Get-MdmEnrollmentConfiguration
    Returns the compliances policies configured in Intune
    .NOTES
    NAME: Get-MdmEnrollmentConfiguration
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Enrollment Configuration"
    $DocSec.Text = "This section contains all Enrollment configurations in Intune."

    $ReturnObj = @()

    $Policies = Invoke-DocGraph -Path "/deviceManagement/deviceEnrollmentConfigurations" -Beta 
    foreach($Policy in $Policies.Value){
        $PolicyA = (Invoke-DocGraph -Path "/deviceManagement/deviceEnrollmentConfigurations/$($Policy.Id)/assignments" -Beta).value
        $ESPtype = $Policy.'@odata.type'
        switch($ESPtype){
            "#microsoft.graph.windows10EnrollmentCompletionPageConfiguration" { $ESPtype = "ESP" }
            "#microsoft.graph.deviceEnrollmentLimitConfiguration" { $ESPtype = "Enrollment Limit" }
            "#microsoft.graph.deviceEnrollmentPlatformRestrictionsConfiguration" { $ESPtype = "Platform Restrictions" }
            "#microsoft.graph.deviceEnrollmentWindowsHelloForBusinessConfiguration" { $ESPtype = "Windows Hello for Business" }
        }

        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = "$($ESPtype) - $($Policy.displayName)"
        $DocSecSingle.Text = $Policy.description
        $DocSecSingle.Objects = $Policy
        $DocSecSingle.Transpose = $true
        $DocSecSingle.SubSections = Get-AssignmentDetail -Assignments $PolicyA
        $ReturnObj += $DocSecSingle
    } 
    $DocSec.SubSections = $ReturnObj

    return $DocSec
}