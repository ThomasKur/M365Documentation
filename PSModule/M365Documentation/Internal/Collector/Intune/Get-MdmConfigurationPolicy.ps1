Function Get-MdmConfigurationPolicy(){
    <#
    .SYNOPSIS
    This function is used to get the all configuration policies from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the configuration policies
    .EXAMPLE
    Get-MdmConfigurationPolicy
    Returns the configuration policies configured in Intune
    .NOTES
    NAME: Get-MdmConfigurationPolicy
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Device Configuration Policies (Settings Catalog)"
    $DocSec.Text = "This section contains a list of all device configuration policies available in Intune."

    $ReturnObj = @()

    # Load Translations
    $translation = Get-Content "$PSScriptRoot\..\..\..\Data\Settings Definitions Export Mar-9 2024.csv" | ConvertFrom-Csv -Delimiter ";" 
            

    [scriptblock]$getValue = {
        Param (
            $Instance,
            $Definitions
        )

        $definitionId = $Instance.settingDefinitionId
        $definition = $Definitions | Where-Object { $_.ID -eq $definitionId }
        $global:valueType = ($Instance.'@odata.type').Replace('#microsoft.graph.deviceManagementConfiguration', '').Replace('Instance', 'Value')

        if ($valueType -eq 'groupSettingCollectionValue') {
            foreach ($child in $Instance.$ValueType.Children | Where-Object { $_ -ne $null }) {
                & $getValue -instance $child -definition $Definitions
            }    
        } else {
            $settingValue = [PSCustomObject]@{
                DisplayName = $definition.displayName
                ID = $definitionId
                Path = $translation | Where-Object { $_.ItemId -eq $definitionId } | Select-Object -ExpandProperty CategoryName
                Value = ($Instance.$ValueType.value.ToString()).Replace($definitionId+"_","")
                ValueName = ($Definitions.options | Where-Object { $_.itemId -eq $Instance.$ValueType.value }).DisplayName
            }

            if($settingValue.Value -eq "System.Object[]") {
                $settingValue.Value = $Instance.$ValueType.value -join ", "
            }

            return $settingValue
        }
    }

    [scriptblock]$getValues = {
        Param (
            $setting
        )
        $settingValues = @()
        $settingValues += & $getValue -Instance $setting.settingInstance -Definitions $setting.settingDefinitions
        
        foreach ($child in $setting.settingInstance.$ValueType.Children | Where-Object { $_ -ne $null }) {
            $SettingValues += & $getValue -instance $child -definition $setting.settingDefinitions
        }

        return $SettingValues
    }

    $Policies = Invoke-DocGraph -Path "/deviceManagement/ConfigurationPolicies" -Beta -FollowNextLink $true  #-ChildPath '?$filter=technologies eq ''mdm'''
    
    foreach($Policy in $Policies.Value) {
        $PolicyA = (Invoke-DocGraph -Path "/deviceManagement/ConfigurationPolicies/$($Policy.Id)/assignments" -Beta).value

        $DocSecSingleValue = New-Object DocSection
        $DocSecSingleValue.Title = "Settings"
        $DocSecSingleValue.Text = ""
        $DocSecSingleValue.Objects = @()
        $DocSecSingleValue.Transpose = $false

        $settings = Invoke-DocGraph -Path (Join-Path -Path "/deviceManagement/ConfigurationPolicies/$($Policy.Id)/settings" -ChildPath '?$expand=settingDefinitions') -FollowNextLink $true -Beta

        foreach($setting in $settings.value) {
            $DocSecSingleValue.Objects += & $getValues -setting $setting
        }

        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $Policy.Name
        $DocSecSingle.Text = $Policy.description
        $DocSecSingle.Objects = $Policy
        $DocSecSingle.Transpose = $false
        $DocSecSingle.SubSections = @()
        $DocSecSingle.SubSections += Get-AssignmentDetail -Assignments $PolicyA
        $DocSecSingle.SubSections += $DocSecSingleValue

        $ReturnObj += $DocSecSingle
    } 

    $DocSec.SubSections = $ReturnObj

    return $DocSec
}
