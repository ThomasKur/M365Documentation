Function Get-MdmSecurityBaseline(){
    <#
    .SYNOPSIS
    This function is used to get the all Security Baseline profiles from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Security Baseline Profiles.
    .EXAMPLE
    Get-MdmSecurityBaseline
    Returns the Security Baseline Profiles configured in Intune
    .NOTES
    NAME: Get-MdmSecurityBaseline
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Security Baselines"
    $DocSec.Text = "This section contains a list of all Security Baseline profiles configured in Intune."

    $ReturnObj = @()

    $templates = (Invoke-DocGraph -Path "/deviceManagement/intents" -Beta).Value
    foreach($template in $templates){
        $settings = Invoke-DocGraph -Path "/deviceManagement/intents/$($template.id)/settings" -Beta
        $templateDetail = Invoke-DocGraph -Path "/deviceManagement/templates/$($template.templateId)" -Beta

        $TempSettings = @()
        foreach($setting in $settings.value){
            # $settingDef = Invoke-MSGraphRequest -Url "https://graph.microsoft.com/beta/deviceManagement/settingDefinitions/$($setting.id)" -ErrorAction SilentlyContinue
            # $displayName = $settingDef.Value.displayName 
            # if($null -eq $displayName){
            $displayName = $setting.definitionId -replace "deviceConfiguration--","" -replace "admx--",""  -replace "_"," "
            # }
            if($null -eq $setting.value){

                if($setting.definitionId -eq "deviceConfiguration--windows10EndpointProtectionConfiguration_firewallRules"){
                    $v = $setting.valueJson | ConvertFrom-Json
                    foreach($item in $v){
                        $TempSetting = [PSCustomObject]@{ Name = "FW Rule - $($item.displayName)"; Value = ($item | ConvertTo-Json) }
                        $TempSettings += $TempSetting
                    }
                } else {
                    
                    $v = ""
                    $TempSetting = [PSCustomObject]@{ Name = $displayName; Value = $v }
                    $TempSettings += $TempSetting
                }
            } else {
                $v = $setting.value
                $TempSetting = [PSCustomObject]@{ Name = $displayName; Value = $v }
                $TempSettings += $TempSetting
            }
            
        }

        $PolicyA = (Invoke-DocGraph -Path "/deviceManagement/intents/$($template.id)/assignments" -Beta).value

        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $template.displayName
        $DocSecSingle.Text = "$($template.description)`n`nPlatform: $($templateDetail.platformType)`nType: $($templateDetail.templateType)`nSubtype: $($templateDetail.templateSubtype)"
        $DocSecSingle.Objects = $TempSettings
        $DocSecSingle.Transpose = $false
        $DocSecSingle.SubSections = Get-AssignmentDetail -Assignments $PolicyA
        $ReturnObj += $DocSecSingle
    }

    $DocSec.SubSections = $ReturnObj

    return $DocSec
}