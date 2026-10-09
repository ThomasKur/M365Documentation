function Get-CopilotPolicySetting(){
    <#
    .SYNOPSIS
    Gets selected Microsoft 365 Copilot policy settings.
    .DESCRIPTION
    Retrieves tenant-level values for three Microsoft-documented Copilot policy setting identifiers.
    The Microsoft Graph beta API supports delegated permissions only.
    .EXAMPLE
    Get-CopilotPolicySetting
    Returns the current values for the selected Copilot policy settings.
    .NOTES
    NAME: Get-CopilotPolicySetting
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    if($script:M365Doc_CloudEnvironment -in @("USGov", "USGovDoD")){
        Write-Warning -Message "Copilot: Skipping policy settings because the Microsoft Graph Copilot policy settings API is not available in $($script:M365Doc_CloudEnvironment)."
        return $null
    }

    $DocSec = New-Object DocSection
    $DocSec.Title = "Policy Settings"
    $DocSec.Text = "Lists tenant-level values for three sample Copilot policy setting identifiers (chat pinning, image generation, and web search). The Microsoft Graph beta API requires delegated CopilotPolicySettings.Read permission and does not support application permissions."
    $DocSec.Objects = @()
    $DocSec.Transpose = $false

    $settingIds = @(
        "microsoft.copilot.copilotchatpinning",
        "microsoft.copilot.imagegeneration",
        "microsoft.copilot.allowwebsearch"
    )

    foreach($settingId in $settingIds){
        $setting = Invoke-DocGraph -Path "/copilot/admin/policySettings/$settingId" -Beta
        if($null -ne $setting){
            $DocSec.Objects += $setting
        }
    }

    if($DocSec.Objects.Count -eq 0){
        return $null
    }

    return $DocSec
}
