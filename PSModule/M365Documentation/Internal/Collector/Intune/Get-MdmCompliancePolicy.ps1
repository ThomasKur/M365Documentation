Function Get-MdmCompliancePolicy(){
    <#
    .SYNOPSIS
    This function is used to get the all compliance policies from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the compliances policies
    .EXAMPLE
    Get-MdmCompliancePolicy
    Returns the compliances policies configured in Intune
    .NOTES
    NAME: Get-MdmCompliancePolicy
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Compliance Policies"
    $DocSec.Text = "This section contains a list of all compliances policies available in Intune."

    $ReturnObj = @()

    $Policies = Invoke-DocGraph -Path "/deviceManagement/deviceCompliancePolicies" -Beta 
    foreach($Policy in $Policies.Value){
        $PolicyA = (Invoke-DocGraph -Path "/deviceManagement/deviceCompliancePolicies/$($Policy.Id)/assignments" -Beta).value

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