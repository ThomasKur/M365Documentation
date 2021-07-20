Function Get-CPConnector(){
    <#
    .SYNOPSIS
    This function is used to get the Cloud Print Connectors from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Print Connectors
    .EXAMPLE
    Get-CPConnector
    Returns the Cloud Print Connectors.
    .NOTES
    NAME: Get-CPConnector
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Connectors"
    $DocSec.Text = "Lists all print connectors that have been registered by using a Universal Print subscription."
    $DocSec.Objects = (Invoke-DocGraph -Path "/print/connectors").Value
    $DocSec.Transpose = $false
    if($null -eq $DocSec.Objects){
        return $null
    } else {
        return $DocSec
    }
    
}