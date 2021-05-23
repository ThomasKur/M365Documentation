Function Get-AADBranding(){
    <#
    .SYNOPSIS
    This function is used to get the Branding from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the FBranding from Azure AD
    .EXAMPLE
    Get-AADBranding
    Returns the Branding defined in Azure AD.
    .NOTES
    NAME: Get-AADBranding
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Organizational branding"
    $DocSec.Text = "Organizations can customize their Azure AD sign-in pages which appear when users sign in to their organization's tenant-specific apps, or when Azure AD identifies the user's tenant from their username. A developer can also read the company's branding information and customize their app experience to tailor it specifically for the signed-in user using their company's branding."
    try{
        $org = Invoke-DocGraph -Path "/organization"
        $DocSec.Objects = Invoke-DocGraph -Path "/organization/$($org.value.id)/branding" -AcceptLanguage "en"
    } catch {}
    $DocSec.Transpose = $true
    if($null -eq $DocSec.Objects){
        return $null
    } else {
        return $DocSec
    }
    
}