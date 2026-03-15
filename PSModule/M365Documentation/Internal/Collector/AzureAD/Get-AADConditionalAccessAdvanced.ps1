Function Get-AADConditionalAccessAdvanced(){
    <#
    .SYNOPSIS
    This function is used to collect additional Conditional Access configuration from Microsoft Graph.
    .DESCRIPTION
    The function collects named locations, authentication strength policies, authentication context class references,
    and Conditional Access templates to complement base policy documentation.
    .EXAMPLE
    Get-AADConditionalAccessAdvanced
    Returns extended Conditional Access configuration in Azure AD.
    .NOTES
    NAME: Get-AADConditionalAccessAdvanced
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection
    $DocSec.Title = "Conditional Access - Advanced"
    $DocSec.Text = "Extended Conditional Access configuration including named locations, authentication strengths, authentication contexts, and templates."
    $DocSec.Transpose = $false
    $DocSec.SubSections = @()

    # Named Locations
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Named Locations"
    $DocSecSingle.Text = "Named locations used in Conditional Access policies."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/identity/conditionalAccess/namedLocations" -FollowNextLink $true).value
    } catch {
        Write-Verbose "Failed to get named locations."
    }
    $DocSecSingle.Transpose = $false
    $DocSec.SubSections += $DocSecSingle

    # Authentication Strength Policies
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Authentication Strength Policies"
    $DocSecSingle.Text = "Built-in and custom authentication strength policies available for Conditional Access grant controls."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/identity/conditionalAccess/authenticationStrength/policies" -Beta -FollowNextLink $true).value
    } catch {
        Write-Verbose "Failed to get authentication strength policies."
    }
    $DocSecSingle.Transpose = $false
    $DocSec.SubSections += $DocSecSingle

    # Authentication Context Class References
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Authentication Contexts"
    $DocSecSingle.Text = "Authentication context class references for application step-up authentication."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/identity/conditionalAccess/authenticationContextClassReferences" -FollowNextLink $true).value
    } catch {
        Write-Verbose "Failed to get authentication context class references."
    }
    $DocSecSingle.Transpose = $false
    $DocSec.SubSections += $DocSecSingle

    # Conditional Access Templates
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Conditional Access Templates"
    $DocSecSingle.Text = "Available Conditional Access policy templates."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/identity/conditionalAccess/templates" -Beta -FollowNextLink $true).value
    } catch {
        Write-Verbose "Failed to get Conditional Access templates."
    }
    $DocSecSingle.Transpose = $false
    $DocSec.SubSections += $DocSecSingle

    if($null -eq $DocSec.SubSections){
        return $null
    } else {
        return $DocSec
    }
}
