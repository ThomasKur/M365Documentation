Function Get-AADAuthMethodAdvanced(){
    <#
    .SYNOPSIS
    This function is used to collect additional authentication method policy settings from Microsoft Graph.
    .DESCRIPTION
    The function collects the root authentication methods policy and additional method configuration types
    that are not included in the base authentication method section.
    .EXAMPLE
    Get-AADAuthMethodAdvanced
    Returns extended authentication methods policy configuration in Azure AD.
    .NOTES
    NAME: Get-AADAuthMethodAdvanced
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection
    $DocSec.Title = "Authentication Method Policies - Advanced"
    $DocSec.Text = "Additional authentication methods policy settings including software OATH and voice."
    $DocSec.Transpose = $false
    $DocSec.SubSections = @()

    # Root policy
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Authentication Methods Root Policy"
    $DocSecSingle.Text = "Tenant-wide authentication methods policy object."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = Invoke-DocGraph -Path "/policies/authenticationMethodsPolicy"
    } catch {
        Write-Verbose "Failed to get authentication methods root policy."
    }
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    # Software OATH
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Software OATH"
    $DocSecSingle.Text = "Software OATH authentication method policy configuration."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = Invoke-DocGraph -Path "/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/softwareOath" -Beta
    } catch {
        Write-Verbose "Failed to get software OATH configuration."
    }
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    # Voice
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Voice"
    $DocSecSingle.Text = "Voice authentication method policy configuration."
    $DocSecSingle.SubSections = @()
    try {
        $DocSecSingle.Objects = Invoke-DocGraph -Path "/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/voice" -Beta
    } catch {
        Write-Verbose "Failed to get voice configuration."
    }
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    if($null -eq $DocSec.SubSections){
        return $null
    } else {
        return $DocSec
    }
}
