Function Get-AADIdentityGovernance(){
    <#
    .SYNOPSIS
    This function is used to collect Identity Governance data from Microsoft Graph.
    .DESCRIPTION
    The function collects access review definitions and instances, and entitlement management objects
    including catalogs, access packages, assignment policies, and connected organizations.
    .EXAMPLE
    Get-AADIdentityGovernance
    Returns Identity Governance configuration in Azure AD.
    .NOTES
    NAME: Get-AADIdentityGovernance
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection
    $DocSec.Title = "Identity Governance"
    $DocSec.Text = "Identity Governance configuration including access reviews and entitlement management."
    $DocSec.Transpose = $false
    $DocSec.SubSections = @()

    # Access Review Definitions
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Access Review Definitions"
    $DocSecSingle.Text = "Configured access review definitions."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/identityGovernance/accessReviews/definitions" -FollowNextLink $true).value
    } catch {
        Write-Verbose "Failed to get access review definitions."
    }
    $DocSecSingle.Transpose = $false
    $DocSec.SubSections += $DocSecSingle

    # Access Review Instances
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Access Review Instances"
    $DocSecSingle.Text = "Access review instances across all definitions."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/identityGovernance/accessReviews/instances" -FollowNextLink $true).value
    } catch {
        Write-Verbose "Failed to get access review instances."
    }
    $DocSecSingle.Transpose = $false
    $DocSec.SubSections += $DocSecSingle

    # Entitlement Management Catalogs
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Entitlement Catalogs"
    $DocSecSingle.Text = "Entitlement management catalogs."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/identityGovernance/entitlementManagement/catalogs" -FollowNextLink $true).value
    } catch {
        Write-Verbose "Failed to get entitlement catalogs."
    }
    $DocSecSingle.Transpose = $false
    $DocSec.SubSections += $DocSecSingle

    # Entitlement Access Packages
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Access Packages"
    $DocSecSingle.Text = "Entitlement management access packages."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/identityGovernance/entitlementManagement/accessPackages" -FollowNextLink $true).value
    } catch {
        Write-Verbose "Failed to get access packages."
    }
    $DocSecSingle.Transpose = $false
    $DocSec.SubSections += $DocSecSingle

    # Entitlement Assignment Policies
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Access Package Assignment Policies"
    $DocSecSingle.Text = "Assignment policies governing access package request and assignment behavior."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/identityGovernance/entitlementManagement/assignmentPolicies" -FollowNextLink $true).value
    } catch {
        Write-Verbose "Failed to get access package assignment policies."
    }
    $DocSecSingle.Transpose = $false
    $DocSec.SubSections += $DocSecSingle

    # Connected Organizations
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Connected Organizations"
    $DocSecSingle.Text = "Connected organizations used in entitlement management."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/identityGovernance/entitlementManagement/connectedOrganizations" -FollowNextLink $true).value
    } catch {
        Write-Verbose "Failed to get connected organizations."
    }
    $DocSecSingle.Transpose = $false
    $DocSec.SubSections += $DocSecSingle

    if($null -eq $DocSec.SubSections){
        return $null
    } else {
        return $DocSec
    }
}
