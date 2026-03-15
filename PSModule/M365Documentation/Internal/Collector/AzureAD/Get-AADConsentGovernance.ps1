Function Get-AADConsentGovernance(){
    <#
    .SYNOPSIS
    This function is used to collect consent governance settings and requests from Microsoft Graph.
    .DESCRIPTION
    The function collects admin consent request policy and app consent requests.
    .EXAMPLE
    Get-AADConsentGovernance
    Returns consent governance configuration in Azure AD.
    .NOTES
    NAME: Get-AADConsentGovernance
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection
    $DocSec.Title = "Consent Governance"
    $DocSec.Text = "Admin consent request workflow policy and app consent requests."
    $DocSec.Transpose = $false
    $DocSec.SubSections = @()

    # Admin Consent Request Policy
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Admin Consent Request Policy"
    $DocSecSingle.Text = "Tenant-level policy for the admin consent request workflow."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = Invoke-DocGraph -Path "/policies/adminConsentRequestPolicy"
    } catch {
        Write-Verbose "Failed to get admin consent request policy."
    }
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    # App Consent Requests
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "App Consent Requests"
    $DocSecSingle.Text = "Current app consent requests in identity governance."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/identityGovernance/appConsent/appConsentRequests" -Beta -FollowNextLink $true).value
    } catch {
        Write-Verbose "Failed to get app consent requests."
    }
    $DocSecSingle.Transpose = $false
    $DocSec.SubSections += $DocSecSingle

    if($null -eq $DocSec.SubSections){
        return $null
    } else {
        return $DocSec
    }
}
