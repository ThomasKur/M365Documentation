Function Get-MdmDeviceComplianceScript(){
    <#
    .SYNOPSIS
    This function is used to get the all Device Compliance Scripts from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Device Compliance Scripts
    .EXAMPLE
    Get-MdmDeviceComplianceScript
    Returns the Device Compliance Scripts configured in Intune
    .NOTES
    NAME: Get-MdmDeviceComplianceScript
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Device Compliance Scripts"
    $DocSec.Text = "This section contains a list of all Device Compliance scripts available in Intune."

    $ReturnObj = @()

    $Policies = Invoke-DocGraph -Path "/deviceManagement/deviceComplianceScripts" -Beta 
    foreach($Policy in $Policies.Value){
        $PolicyA = (Invoke-DocGraph -Path "/deviceManagement/deviceComplianceScripts/$($Policy.Id)/assignments" -Beta).value

        $currentScript = Invoke-DocGraph -Path "/deviceManagement/deviceComplianceScripts/$($Policy.id)" -Beta
        $ScriptContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($currentScript.detectionScriptContent))
        $ScriptContent = $ScriptContent -replace "`0", ""
        $ScriptContent = $ScriptContent.Substring(1)
        
        $allScript = [PSCustomObject]@{
            id = $currentScript.id
            publisher = $currentScript.publisher
            version = $currentScript.version
            displayName = $currentScript.displayName
            description = $currentScript.description
            enforceSignatureCheck = $Policy.enforceSignatureCheck
            runAs32Bit = $Policy.runAs32Bit
            runAsAccount = $Policy.runAsAccount
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