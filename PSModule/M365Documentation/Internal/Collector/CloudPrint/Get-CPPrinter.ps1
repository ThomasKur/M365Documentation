Function Get-CPPrinter(){
    <#
    .SYNOPSIS
    This function is used to get the Cloud Printers from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Printers
    .EXAMPLE
    Get-CPPrinter
    Returns the Cloud Printers.
    .NOTES
    NAME: Get-CPPrinter
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Printers"
    $DocSec.Text = "Lists all printers that have been registered by using a Universal Print subscription."
    $DocSec.Transpose = $false
    
    $printers = (Invoke-DocGraph -Path "/print/printers" -Beta).Value
    # Printer
    foreach($printer in $printers){
        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $printer.displayName
        $DocSecSingle.Objects = $printer
        $DocSecSingle.SubSections = @()
        $DocSecSingle.Transpose = $true

        $DocSecSingleShare = New-Object DocSection
        $DocSecSingleShare.Title = Shares
        $DocSecSingleShare.Objects = (Invoke-DocGraph -Path "/print/printers/$($printer.id)/shares").Value
        $DocSecSingleShare.SubSections = @()
        $DocSecSingleShare.Transpose = $false
        $DocSecSingle.SubSections += $DocSecSingleShare

        $DocSecSingleCon = New-Object DocSection
        $DocSecSingleCon.Title = Connectors
        $DocSecSingleCon.Objects = (Invoke-DocGraph -Path "/print/printers/$($printer.id)/connectors").Value
        $DocSecSingleCon.SubSections = @()
        $DocSecSingleCon.Transpose = $false
        $DocSecSingle.SubSections += $DocSecSingleCon

        $DocSec.SubSections += $DocSecSingle
    }


    if($null -eq $DocSec.SubSections){
        return $null
    } else {
        return $DocSec
    }
    
}