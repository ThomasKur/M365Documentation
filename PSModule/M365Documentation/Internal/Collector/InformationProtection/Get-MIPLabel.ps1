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

    if($script:M365Doc_CloudEnvironment -in @("USGov", "USGovDoD")){
        Write-Warning -Message "InformationProtection: Skipping sensitivity labels because the Microsoft Graph sensitivity labels API is not available in $($script:M365Doc_CloudEnvironment)."
        return $null
    }

    Test-TokenExpiration
    $path = "/security/informationProtection/sensitivityLabels"
    if($null -ne $script:token.Account){
        $path = "/me/security/informationProtection/sensitivityLabels"
        Write-Warning -Message "InformationProtection only documents labels available to the signed-in user when running interactive. Use app-only authentication with InformationProtectionPolicy.Read.All to document organization labels."
    }

    $DocSec = New-Object DocSection

    $DocSec.Title = "Labels"
    $DocSec.Text = "Lists sensitivity labels available to the organization or signed-in user in Microsoft Information Protection."
    $DocSec.Objects = (Invoke-DocGraph -Path $path -Beta).Value
    $DocSec.Transpose = $false
    if($null -eq $DocSec.Objects){
        return $null
    } else {
        return $DocSec
    }
    
}