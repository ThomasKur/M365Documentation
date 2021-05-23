Function Get-AADPolicy(){
    <#
    .SYNOPSIS
    This function is used to get multiple policies from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets multiple policies from Azure AD
    .EXAMPLE
    Get-AADPolicy
    Returns the policies defined in Azure AD.
    .NOTES
    NAME: Get-AADPolicy
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "AAD Policies"
    $DocSec.Text = ""
    $DocSec.Transpose = $false
    $DocSec.SubSections = @()

    # Authentication Flow Policy
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Authentication Flow Policy"
    $DocSecSingle.Text = "Represents the policy configuration of self-service sign-up experience at a tenant level that lets external users request to sign up for approval. It contains information, such as the identifier, display name, and description, and indicates whether self-service sign-up is enabled for the policy."
    $DocSecSingle.SubSections = @()
    try{
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/policies/authenticationFlowsPolicy").value
    } catch {}
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    # Mobility Management Policy
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Mobility Management Policy"
    $DocSecSingle.Text = "In Azure AD, a mobility management policy represents an auto-enrollment configuration for a mobility management (MDM or MAM) application. These policies are only applicable to devices based on Windows 10 OS and its derivatives (Surface Hub, Hololens etc.). Auto-enrollment enables organizations to automatically enroll devices into their chosen mobility management application as part of Azure AD join or Azure AD register process on Windows 10 devices."
    $DocSecSingle.SubSections = @()
    try{
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/policies/mobileDeviceManagementPolicies" -Beta).value
    } catch {}
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    # Permission Grant Policy
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Permission Grant Policy"
    $DocSecSingle.Text = "A permission grant policy is used to specify the conditions under which consent can be granted. A permission grant policy consists of a list of includes condition sets, and a list of excludes condition sets. For an event to match a permission grant policy, it must match at least one of the includes conditions sets, and none of the excludes condition sets."
    $DocSecSingle.SubSections = @()
    try{
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/policies/permissionGrantPolicies" -Beta).value
    } catch {}
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    
    # Home Realm Discovery Policy
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Home Realm Discovery Policy"
    $DocSecSingle.Text = "Represents a policy to control Azure Active Directory authentication behavior for federated users, in particular for auto-acceleration and user authentication restrictions in federated domains. You can set homeRealmDiscoveryPolicy for all service principals in your organization, or for specific service principals in your organization. For more scenario and policy details see Configure Azure AD sign in behavior for an application by using a Home Realm Discovery policy as well as Sign-in to Azure Active Directory using email as an alternate login ID."
    $DocSecSingle.SubSections = @()
    try{
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/policies/homeRealmDiscoveryPolicies" -Beta).value
    } catch {}
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    # Activity Based Timeout Policy
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Activity Based Timeout Policy"
    $DocSecSingle.Text = "Represents a policy that can control the idle timeout for web sessions for applications that support activity-based timeout functionality. Applications enforce automatic signout after a period of inactivity. This type of policy can only be applied at the organization level (by setting the isOrganizationDefault property to true)."
    $DocSecSingle.SubSections = @()
    try{
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/policies/activityBasedTimeoutPolicies" -Beta).value
    } catch {}
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    # Token Issuance Policy
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Token Issuance Policy"
    $DocSecSingle.Text = "Represents the policy to specify the characteristics of SAML tokens issued by Azure AD. You can use token-issuance policies to:

    Set signing options
    Set signing algorithm
    Set SAML token version"
    $DocSecSingle.SubSections = @()
    try{
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/policies/tokenIssuancePolicies" -Beta).value
    } catch {}
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    # Token Lifetime Policy
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Token Lifetime Policy"
    $DocSecSingle.Text = "Represents a policy that can control the lifetime of a JWT access token, an ID token or a SAML 1.1/2.0 token issued by Azure Active Directory (Azure AD). You can set token lifetimes for all apps in your organization, for a multi-tenant (multi-organization) application, or for a specific service principal in your organization. For more scenario details see Configurable token lifetimes in Azure Active Directory.
    Note: Configuring this policy for Refresh Tokens and Session Tokens is not supported."
    $DocSecSingle.SubSections = @()
    try{
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/policies/tokenLifetimePolicies" -Beta).value
    } catch {}
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    # Security Defaults Policy
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Security Defaults Policy"
    $DocSecSingle.Text = "Represents the Azure Active Directory security defaults policy. Security defaults contain preconfigured security settings that protect against common attacks."
    $DocSecSingle.SubSections = @()
    try{
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/policies/identitySecurityDefaultsEnforcementPolicy" -Beta)
    } catch {}
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    # Continuous Access Evaluation Policy
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Continuous Access Evaluation Policy"
    $DocSecSingle.Text = "Continuous Access Evaluation (CAE) manages authentication sessions in real time. CAE allows customers to handle access to resources by supporting instant revocation events."
    $DocSecSingle.SubSections = @()
    try{
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/identity/continuousAccessEvaluationPolicy" -Beta)
    } catch {}
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    # Authorization Policy
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Authorization Policy"
    $DocSecSingle.Text = "Represents a policy that can control Azure Active Directory authorization settings. It's a singleton that inherits from base policy type, and always exists for the tenant."
    $DocSecSingle.SubSections = @()
    try{
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/policies/authorizationPolicy/authorizationPolicy" -Beta)
    } catch {}
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    if($null -eq $DocSec.SubSections){
        return $null
    } else {
        return $DocSec
    }
    
}