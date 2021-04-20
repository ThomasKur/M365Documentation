Function Get-MdmAdmxConfigurationProfile(){
    <#
    .SYNOPSIS
    This function is used to get the all ADMX backed configuration profiles from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the ADMX backed configuration profiles
    .EXAMPLE
    Get-MdmAdmxConfigurationProfile
    Returns the ADMX backed configuration profiles configured in Intune
    .NOTES
    NAME: Get-MdmAdmxConfigurationProfile
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Device Configuration (ADMX)"
    $DocSec.Text = "This section contains a list of all device configuration profiles which are backed by ADMX available in Intune."

    $ReturnObj = @()

    $Policies = Invoke-DocGraph -Path "/deviceManagement/groupPolicyConfigurations" -Beta 
    foreach($Policy in $Policies.Value){
        $PolicyA = (Invoke-DocGraph -Path "/deviceManagement/groupPolicyConfigurations/$($Policy.Id)/assignments" -Beta).value

        $DocSecSingleValue = New-Object DocSection
        $DocSecSingleValue.Title = "Settings"
        $DocSecSingleValue.Text = ""
        $DocSecSingleValue.Objects = @()
        $DocSecSingleValue.Transpose = $false

        $values = Invoke-DocGraph -Path "/deviceManagement/groupPolicyConfigurations/$($Policy.Id)/definitionValues" -Beta 
        foreach($value in $values.value){
            try{
                $definition = Invoke-DocGraph -Path "/deviceManagement/groupPolicyConfigurations/$($Policy.Id)/definitionValues/$($value.id)/definition" -Beta
                $res = Invoke-DocGraph -Path "/deviceManagement/groupPolicyConfigurations/$($Policy.Id)/definitionValues/$($value.id)/presentationValues" -Beta
                if($null -ne $res.value.Value){
                    $AdditionalConfig = if($res.value.value.GetType().baseType.Name -eq "Array"){ $res.value.value -join ", "  } else { $res.value.value }
                } else {
                    $AdditionalConfig = ""
                }
                $DocSecSingleValue.Objects += [PSCustomObject]@{ 
                    DisplayName = $definition.displayName
                    #ExplainText = $definition.explainText
                    Scope = $definition.classType
                    Path = $definition.categoryPath
                    SupportedOn = $definition.supportedOn
                    State = if($value.enabled -eq $true){"Enabled"} else {"Disabled"}
                    Value = $AdditionalConfig
                }
            } catch {
                Write-Log -Message "Error reading ADMX setting" -Type Warn -Exception $_.Exception
            }
        }

        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $Policy.displayName
        $DocSecSingle.Text = $Policy.description
        $DocSecSingle.Objects = $Policy
        $DocSecSingle.Transpose = $true
        $DocSecSingle.SubSections = @()
        $DocSecSingle.SubSections += Get-AssignmentDetail -Assignments $PolicyA
        $DocSecSingle.SubSections += $DocSecSingleValue
        $ReturnObj += $DocSecSingle
    } 

    


    
    $DocSec.SubSections = $ReturnObj

    return $DocSec
}