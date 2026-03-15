Function Get-AADCrossTenantAccess(){
    <#
    .SYNOPSIS
    This function is used to collect cross-tenant and external identities policies from Microsoft Graph.
    .DESCRIPTION
    The function collects cross-tenant access policy baseline settings, partner-specific settings,
    and the tenant external identities policy.
    .EXAMPLE
    Get-AADCrossTenantAccess
    Returns cross-tenant and external identities policy configuration in Azure AD.
    .NOTES
    NAME: Get-AADCrossTenantAccess
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection
    $DocSec.Title = "Cross-Tenant Access"
    $DocSec.Text = "Cross-tenant and external identities policy configuration."
    $DocSec.Transpose = $false
    $DocSec.SubSections = @()

    # Cross-tenant baseline policy
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Cross-Tenant Access Policy"
    $DocSecSingle.Text = "Tenant-wide baseline cross-tenant access policy settings."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = Invoke-DocGraph -Path "/policies/crossTenantAccessPolicy"
    } catch {
        Write-Verbose "Failed to get cross-tenant access policy."
    }
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    # Partner-specific cross-tenant settings
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Cross-Tenant Partner Settings"
    $DocSecSingle.Text = "Partner-specific cross-tenant access settings."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/policies/crossTenantAccessPolicy/partners" -FollowNextLink $true).value
    } catch {
        Write-Verbose "Failed to get cross-tenant partner settings."
    }
    $DocSecSingle.Transpose = $false
    $DocSec.SubSections += $DocSecSingle

    # External identities policy
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "External Identities Policy"
    $DocSecSingle.Text = "Tenant-wide external identities self-service leave and related settings."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = Invoke-DocGraph -Path "/policies/externalIdentitiesPolicy" -Beta
    } catch {
        Write-Verbose "Failed to get external identities policy."
    }
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    if($null -eq $DocSec.SubSections){
        return $null
    } else {
        return $DocSec
    }
}
