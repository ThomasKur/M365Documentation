Function Get-MdmExchangeConnector(){
    <#
    .SYNOPSIS
    This function is used to get the all Exchange Connectors defined from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Exchange Connectors defined
    .EXAMPLE
    Get-MdmExchangeConnector
    Returns the Exchange Connectors configured in Intune
    .NOTES
    NAME: Get-MdmExchangeConnector
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Exchange Connector"
    $DocSec.Text = "This section contains all Exchange COnnectors defined in Intune."

    $ReturnObj = @()

    $EXCs = Invoke-DocGraph -Path "/deviceManagement/exchangeConnectors"
    foreach($EXC in $EXCs.Value){
        
        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $EXC.displayName
        $DocSecSingle.Text = $EXC.description
        $DocSecSingle.Objects = $EXC
        $DocSecSingle.Transpose = $true
        $ReturnObj += $DocSecSingle
    } 
    $DocSec.SubSections = $ReturnObj


    return $DocSec
}