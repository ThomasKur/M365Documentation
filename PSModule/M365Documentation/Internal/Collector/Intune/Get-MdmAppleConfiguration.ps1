Function Get-MdmAppleConfiguration(){
    <#
    .SYNOPSIS
    This function is used to get the Apple specific configuration from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Apple specific configuration
    .EXAMPLE
    Get-AppleConfiguration
    Returns the Apple specific configuration of Intune
    .NOTES
    NAME: Get-AppleConfiguration
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Apple Configuration"
    $DocSec.Text = "This section contains the Apple specific Intune configuration. The following Apple push notification certificate is configured:"
    $DocSec.Objects = Invoke-DocGraph -Path "/deviceManagement/applePushNotificationCertificate" 
    $DocSec.Transpose = $true
    $ReturnObj = @()

    $Vpps = Invoke-DocGraph -Path "/deviceAppManagement/vppTokens"
    
    foreach($Vpp in $Vpps.Value){
        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $Vpp.appleIdentifier
        $DocSecSingle.Objects = $Vpp
        $DocSecSingle.Transpose = $true
        $ReturnObj += $DocSecSingle
    } 
    $DocSec.SubSections = $ReturnObj

    if($null -eq $DocSec.Objects){
        return $null
    } else {
        return $DocSec
    }
    
}