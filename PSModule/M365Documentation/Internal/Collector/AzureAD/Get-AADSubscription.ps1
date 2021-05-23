Function Get-AADSubscription(){
    <#
    .SYNOPSIS
    This function is used to get the Subscription details from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Subscription details from Azure AD
    .EXAMPLE
    Get-AADSubscription
    Returns the Subscription defined in Azure AD.
    .NOTES
    NAME: Get-AADSubscription
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Subscriptions"
    $DocSec.Text = "Contains information about Subscription/Online Services that a company is subscribed to."
    $DocSec.Objects = (Invoke-DocGraph -Path "/subscribedSkus")
    $DocSec.Transpose = $true

    if($null -eq $DocSec.Objects){
        return $null
    } else {
        return $DocSec
    }
    

}