Function Get-AADAuthMethod(){
    <#
    .SYNOPSIS
    This function is used to get the Auth Methods from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Auth Methods from Azure AD
    .EXAMPLE
    Get-AADAuthMethod
    Returns the Auth Methods defined in Azure AD.
    .NOTES
    NAME: Get-AADAuthMethod
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Authentication Method Policies"
    $DocSec.Text = "Authentication methods policies define authentication methods and the users that are allowed to use them to sign in and perform multi-factor authentication (MFA) in Azure Active Directory (Azure AD). Authentication methods policies that can be managed in Microsoft Graph include FIDO2 Security Keys and Passwordless Phone Sign-in with Microsoft Authenticator app."
    $DocSec.Objects = @()
    $DocSec.Transpose = $true
    $DocSec.SubSections = @()
    
    # FIDO
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "FIDO2"
    $DocSecSingle.SubSections = @()
    try{
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/fido2" -Beta).Value
    } catch {}
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    # Authenticator
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Authenticator"
    $DocSecSingle.SubSections = @()
    try{
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/microsoftAuthenticator" -Beta).Value
    } catch {}
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    # Temporary Access Pass
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Temporary Access Pass"
    $DocSecSingle.SubSections = @()
    try{
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/TemporaryAccessPass" -Beta)
    } catch {}
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    # Email
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Email"
    $DocSecSingle.SubSections = @()
    try{
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/email" -Beta)
    } catch {}
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    # Text Message
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Text Message"
    $DocSecSingle.SubSections = @()
    try{
        $DocSecSingle.Objects = (Invoke-DocGraph -Path "/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/sms" -Beta)
    } catch {}
    $DocSecSingle.Transpose = $true
    $DocSec.SubSections += $DocSecSingle

    return $DocSec

    
}