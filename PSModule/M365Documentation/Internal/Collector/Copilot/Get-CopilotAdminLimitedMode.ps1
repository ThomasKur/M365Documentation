function Get-CopilotAdminLimitedMode(){
    <#
    .SYNOPSIS
    Gets the Microsoft 365 Copilot admin limited mode setting.
    .DESCRIPTION
    Retrieves the tenant's Copilot admin limited mode configuration from Microsoft Graph.
    The API supports delegated permissions only.
    .EXAMPLE
    Get-CopilotAdminLimitedMode
    Returns the Copilot admin limited mode configuration.
    .NOTES
    NAME: Get-CopilotAdminLimitedMode
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    if($script:M365Doc_CloudEnvironment -in @("USGov", "USGovDoD")){
        Write-Warning -Message "Copilot: Skipping admin limited mode because the Microsoft Graph API is not available in $($script:M365Doc_CloudEnvironment)."
        return $null
    }

    $result = Invoke-DocGraph -Path "/copilot/admin/settings/limitedMode"
    if($null -eq $result){
        return $null
    }

    $DocSec = New-Object DocSection
    $DocSec.Title = "Admin Limited Mode"
    $DocSec.Text = "Lists the Microsoft 365 Copilot admin limited mode configuration. Requires delegated CopilotSettings-LimitedMode.Read permission and the Global Reader directory role; application permissions are not supported."
    $DocSec.Objects = $result
    $DocSec.Transpose = $true

    return $DocSec
}
