Function Get-W365OnPremConnection(){
    <#
    .SYNOPSIS
    This function is used to get the Windows 365 On Prem Connections from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the On Prem Connections
    .EXAMPLE
    Get-W365OnPremConnection
    Returns the On Prem Connections defined in Windows 365.
    .NOTES
    NAME: Get-W365OnPremConnection
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "On-premises Connections"
    $DocSec.Text = "Lists all Azure resource information that can be used to establish on-premises network connectivity for Cloud PCs."
    $DocSec.Objects = (Invoke-DocGraph -Path "/deviceManagement/virtualEndpoint/onPremisesConnections" -Beta).Value
    $DocSec.Transpose = $false
    if($null -eq $DocSec.Objects){
        return $null
    } else {
        return $DocSec
    }
    
}