Function Get-AADTermsOfUse(){
    <#
    .SYNOPSIS
    This function is used to collect Terms of Use agreements from Microsoft Graph.
    .DESCRIPTION
    The function collects agreement objects and attempts to include file metadata for each agreement.
    .EXAMPLE
    Get-AADTermsOfUse
    Returns Terms of Use agreements in Azure AD.
    .NOTES
    NAME: Get-AADTermsOfUse
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection
    $DocSec.Title = "Terms Of Use"
    $DocSec.Text = "Configured Terms of Use agreements and related file metadata."
    $DocSec.Transpose = $false
    $DocSec.SubSections = @()

    $agreements = @()
    try {
        $agreements = (Invoke-DocGraph -Path "/identityGovernance/termsOfUse/agreements" -FollowNextLink $true).value
    } catch {
        Write-Verbose "Failed to get Terms of Use agreements."
    }

    # Agreement list
    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Agreements"
    $DocSecSingle.Text = "All configured Terms of Use agreements."
    $DocSecSingle.SubSections = @()
    $DocSecSingle.Objects = $agreements
    $DocSecSingle.Transpose = $false
    $DocSec.SubSections += $DocSecSingle

    # Agreement files overview
    $agreementFiles = @()
    foreach($agreement in $agreements){
        try {
            $files = (Invoke-DocGraph -Path "/identityGovernance/termsOfUse/agreements/$($agreement.id)/files" -FollowNextLink $true).value
            foreach($file in $files){
                $agreementFiles += [PSCustomObject]@{
                    AgreementId = $agreement.id
                    AgreementDisplayName = $agreement.displayName
                    FileId = $file.id
                    FileDisplayName = $file.displayName
                    Language = $file.language
                    IsDefault = $file.isDefault
                }
            }
        } catch {
            Write-Verbose "Failed to get file metadata for agreement $($agreement.id)."
        }
    }

    $DocSecSingle = New-Object DocSection
    $DocSecSingle.Title = "Agreement Files"
    $DocSecSingle.Text = "File metadata for agreement localizations and versions."
    $DocSecSingle.SubSections = @()
    $DocSecSingle.Objects = $agreementFiles
    $DocSecSingle.Transpose = $false
    $DocSec.SubSections += $DocSecSingle

    if($null -eq $DocSec.SubSections){
        return $null
    } else {
        return $DocSec
    }
}
