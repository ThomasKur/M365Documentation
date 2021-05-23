Function Get-AADIdentityProvider(){
    <#
    .SYNOPSIS
    This function is used to get the registered Identity Providers from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Identity Providers from Azure AD
    .EXAMPLE
    Get-AADIdentityProvider
    Returns the Identity Providers defined in Azure AD.
    .NOTES
    NAME: Get-AADIdentityProvider
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Identity Providers"
    $DocSec.Text = "Represents an Azure Active Directory (Azure AD) identity provider. The identity provider can be Microsoft, Google, Facebook, Amazon, LinkedIn, or Twitter. The following Identity Providers are in Preview: Weibo, QQ, WeChat, GitHub and any OpenID Connect supported providers."
    try{
        $DocSec.Objects = (Invoke-DocGraph -Path "/identity/identityProviders" -Beta).Value
    } catch {}
    $DocSec.Transpose = $false
    if($null -eq $DocSec.Objects){
        return $null
    } else {
        return $DocSec
    }
    
}