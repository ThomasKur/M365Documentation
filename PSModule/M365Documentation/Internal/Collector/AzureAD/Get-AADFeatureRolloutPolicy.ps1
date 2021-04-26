Function Get-AADFeatureRolloutPolicy(){
    <#
    .SYNOPSIS
    This function is used to get the Feature Rollout policies from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Feature Rollout policies from Azure AD
    .EXAMPLE
    Get-AADFeatureRolloutPolicy
    Returns the Feature Rollout policies defined in Azure AD.
    .NOTES
    NAME: Get-AADFeatureRolloutPolicy
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Feature rollout policy"
    $DocSec.Text = "Creating a feature rollout policy helps tenant administrators to pilot features of Azure AD with a specific group before enabling features for entire organization. This minimizes the impact and helps administrators to test and rollout authentication related features gradually."
    try{
        $DocSec.Objects = (Invoke-DocGraph -Path "/policies/featureRolloutPolicies").Value
    } catch {}
    $DocSec.Transpose = $false
    if($null -eq $DocSec.Objects){
        return $null
    } else {
        return $DocSec
    }
    
}