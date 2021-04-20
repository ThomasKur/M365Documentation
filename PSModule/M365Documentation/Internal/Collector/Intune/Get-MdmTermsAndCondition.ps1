Function Get-MdmTermsAndCondition(){
    <#
    .SYNOPSIS
    This function is used to get the all Terms and Conditions policies from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Terms and Conditions
    .EXAMPLE
    Get-MdmTermsAndConditions
    Returns the Terms and Conditions configured in Intune
    .NOTES
    NAME: Get-MdmTermsAndConditions
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Terms and Conditions"
    $DocSec.Text = "This section contains a list of all Terms and Conditions available in Intune."

    $ReturnObj = @()

    $Policies = Invoke-DocGraph -Path "/deviceManagement/termsAndConditions" -Beta 
    foreach($Policy in $Policies.Value){
        $PolicyA = (Invoke-DocGraph -Path "/deviceManagement/termsAndConditions/$($Policy.Id)/assignments" -Beta).value

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