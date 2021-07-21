Function Get-MIPLabel(){
    <#
    .SYNOPSIS
    This function is used to get the Microsoft Information Protection Labels from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the MIP Labels
    .EXAMPLE
    Get-MIPLabel
    Returns the MIP Labels.
    .NOTES
    NAME: Get-MIPLabel
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Labels"
    $DocSec.Text = "Lists all labels that have been configured in Microsoft Information Protection."
    Write-Warning -Message "InformationProtection only documents all labels when executed with an app registration and not when running interactive."
    $DocSec.Objects = (Invoke-DocGraph -Path "/informationProtection/policy/labels").Value
    $DocSec.Transpose = $false
    if($null -eq $DocSec.Objects){
        return $null
    } else {
        return $DocSec
    }
    
}