Function Get-MdmPowerShellScript(){
    <#
    .SYNOPSIS
    This function is used to get the all Powershell Scripts from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Powershell Scripts
    .EXAMPLE
    Get-MdmPowerShellScript
    Returns the Powershell Scripts configured in Intune
    .NOTES
    NAME: Get-MdmPowerShellScript
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "PowerShell Scripts"
    $DocSec.Text = "This section contains a list of all PowerShell scripts available in Intune."

    $ReturnObj = @()

    $Policies = Invoke-DocGraph -Path "/deviceManagement/deviceManagementScripts" -Beta 
    foreach($Policy in $Policies.Value){
        $PolicyA = (Invoke-DocGraph -Path "/deviceManagement/deviceManagementScripts/$($Policy.Id)/assignments" -Beta).value

        $currentScript = Invoke-DocGraph -Path "/deviceManagement/deviceManagementScripts/$($Policy.id)" -Beta
        $ScriptContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($currentScript.scriptContent))
        $ScriptContent = $ScriptContent -replace "`0", ""
        $ScriptContent = $ScriptContent.Substring(1)
        
        $allScript = [PSCustomObject]@{
            id = $currentScript.id
            displayName = $currentScript.displayName
            description = $currentScript.description
            enforceSignatureCheck = $Policy.enforceSignatureCheck
            runAs32Bit = $Policy.runAs32Bit
            runAsAccount = $Policy.runAsAccount
            fileName = $Policy.fileName
            scriptContent = $ScriptContent
        }

        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $Policy.displayName
        $DocSecSingle.Text = $Policy.description
        $DocSecSingle.Objects = $allScript
        $DocSecSingle.Transpose = $true
        $DocSecSingle.SubSections = Get-AssignmentDetail -Assignments $PolicyA
        $ReturnObj += $DocSecSingle
    } 
    $DocSec.SubSections = $ReturnObj

    return $DocSec
}