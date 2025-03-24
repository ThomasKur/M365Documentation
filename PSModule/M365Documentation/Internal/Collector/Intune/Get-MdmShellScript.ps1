Function Get-MdmShellScript(){
    <#
    .SYNOPSIS
    This function is used to get the all shell Scripts from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the shell Scripts
    .EXAMPLE
    Get-MdmShellScript
    Returns the shell Scripts configured in Intune
    .NOTES
    NAME: Get-MdmShellScript
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Shell Scripts"
    $DocSec.Text = "This section contains a list of all Shell scripts available in Intune."

    $ReturnObj = @()

    $Policies = Invoke-DocGraph -Path "/deviceManagement/deviceShellScripts" -Beta 
    foreach($Policy in $Policies.Value){
        
        $currentScript = Invoke-DocGraph -Path "/deviceManagement/deviceShellScripts/$($Policy.id)" -Beta
        $ScriptContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($currentScript.scriptContent))
        $ScriptContent = $ScriptContent -replace "`0", ""
        $ScriptContent = $ScriptContent.Substring(1)
        
        $allScript = [PSCustomObject]@{
            id = $currentScript.id
            displayName = $currentScript.displayName
            description = $currentScript.description
            runAsAccount = $Policy.runAsAccount
            fileName = $Policy.fileName
            scriptContent = $ScriptContent
            executionFrequency = $Policy.executionFrequency
            blockExecutionNotifications = $Policy.blockExecutionNotifications

        }

        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $Policy.displayName
        $DocSecSingle.Text = $Policy.description
        $DocSecSingle.Objects = $allScript
        $DocSecSingle.Transpose = $true
        $ReturnObj += $DocSecSingle
    } 
    $DocSec.SubSections = $ReturnObj

    return $DocSec
}