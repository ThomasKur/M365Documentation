Function Get-MdmDeviceHealthScript(){
    <#
    .SYNOPSIS
    This function is used to get the all Device Health Scripts from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Device Health Scripts
    .EXAMPLE
    Get-MdmDeviceHealthScript
    Returns the Device Health Scripts configured in Intune
    .NOTES
    NAME: Get-MdmDeviceHealthScript
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Device Health Scripts"
    $DocSec.Text = "This section contains a list of all Device Health scripts available in Intune."

    $ReturnObj = @()

    $Policies = Invoke-DocGraph -Path "/deviceManagement/deviceHealthScripts" -Beta 
    foreach($Policy in $Policies.Value){
        $PolicyA = (Invoke-DocGraph -Path "/deviceManagement/deviceHealthScripts/$($Policy.Id)/assignments" -Beta).value

        $currentScript = Invoke-DocGraph -Path "/deviceManagement/deviceHealthScripts/$($Policy.id)" -Beta
        $ScriptContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($currentScript.remediationScriptContent))
        $ScriptContent = $ScriptContent -replace "`0", ""
        if($ScriptContent -ne "" -and $null -ne $ScriptContent) {
            $ScriptContent = $ScriptContent.Substring(1)
        }
        $ScriptContentDet = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($currentScript.detectionScriptContent))
        $ScriptContentDet = $ScriptContentDet -replace "`0", ""
        $ScriptContentDet = $ScriptContentDet.Substring(1)
        
        $allScript = [PSCustomObject]@{
            id = $currentScript.id
            publisher = $currentScript.publisher
            version = $currentScript.version
            displayName = $currentScript.displayName
            description = $currentScript.description
            enforceSignatureCheck = $Policy.enforceSignatureCheck
            runAs32Bit = $Policy.runAs32Bit
            runAsAccount = $Policy.runAsAccount
            remediationScriptContent = $ScriptContent
            detectionScriptContent = $ScriptContentDet
            isGlobalScript = $Policy.isGlobalScript
            deviceHealthScriptType = $Policy.deviceHealthScriptType
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