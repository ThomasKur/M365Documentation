Function Get-AADConditionalAccessSplit(){
    <#
    .SYNOPSIS
    This function is used to get the all conditional access policies from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the conditional access policies
    .EXAMPLE
    Get-AADConditionalAccessSplit
    Returns the Conditional Access Policies in Azure AD
    .NOTES
    NAME: Get-AADConditionalAccessSplit
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Conditional Access Policies"
    $DocSec.Text = "This section contains a list of all conditional Access policies configured in Azure AD."

    $ReturnObj = @()

    $Policies = Invoke-DocGraph -Path "/identity/conditionalAccess/policies" -Beta 
    foreach($CAPolicy in $Policies.Value){

        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $CAPolicy.displayName
        $DocSecSingle.SubSections = @()



        $ResultCAPolicy = New-Object -Type PSObject
        $ResultCAPolicy | Add-Member Noteproperty "M_Id" $CAPolicy.id
        $ResultCAPolicy | Add-Member Noteproperty "M_DisplayName" $CAPolicy.displayName
        $ResultCAPolicy | Add-Member Noteproperty "M_Created" $CAPolicy.createdDateTime
        $ResultCAPolicy | Add-Member Noteproperty "M_Modified" $CAPolicy.modifiedDateTime
        $ResultCAPolicy | Add-Member Noteproperty "M_State" $CAPolicy.state
        $ResultCAPolicy | Add-Member Noteproperty "C_SignInRiskLevel" ($CAPolicy.conditions.signInRiskLevels -join ",")
        $ResultCAPolicy | Add-Member Noteproperty "C_ClientAppTypes" ($CAPolicy.conditions.clientAppTypes -join ",")
        $ResultCAPolicy | Add-Member Noteproperty "C_PlatformsInclude" ($CAPolicy.conditions.platforms.includePlatforms -join ",")
        $ResultCAPolicy | Add-Member Noteproperty "C_PlatformsExclude" ($CAPolicy.conditions.platforms.excludePlatforms -join ",")
        $ResultCAPolicy | Add-Member Noteproperty "C_LocationsInclude" ($CAPolicy.conditions.locations.includeLocations -join ",")
        $ResultCAPolicy | Add-Member Noteproperty "C_LocationsExclude" ($CAPolicy.conditions.locations.excludeLocations -join ",")
        $ResultCAPolicy | Add-Member Noteproperty "C_DeviceStates" ($CAPolicy.conditions.deviceStates -join ",")
        $ResultCAPolicy | Add-Member Noteproperty "C_Devices" ($CAPolicy.conditions.devices -join ",")
        
        # Application Condition
        $IncludeApps = @()
        foreach($app in $CAPolicy.conditions.applications.includeApplications){
            $IncludeApps += Get-AzureADApplicationName -AppId $app
        }
        $ResultCAPolicy | Add-Member Noteproperty "C_ApplicationsInclude" ($IncludeApps -join [System.Environment]::NewLine)

        $ExcludeApps = @()
        foreach($app in $CAPolicy.conditions.applications.excludeApplications){
            $ExcludeApps += Get-AzureADApplicationName -AppId $app
        }
        $ResultCAPolicy | Add-Member Noteproperty "C_ApplicationsExclude" ($ExcludeApps -join [System.Environment]::NewLine)

        $ResultCAPolicy | Add-Member Noteproperty "C_ApplicationsIncludeUserActions" ($CAPolicy.conditions.applications.includeUserActions -join ",")

        #User Conditions
        $IncludeUsers = @()
        foreach($user in $CAPolicy.conditions.users.includeUsers){
            $IncludeUsers += Get-AzureADUser -UserId $user
        }
        $ResultCAPolicy | Add-Member Noteproperty "C_UsersInclude" ($IncludeUsers -join [System.Environment]::NewLine)

        $ExcludeUsers = @()
        foreach($user in $CAPolicy.conditions.users.excludeUsers){
            $ExcludeUsers += Get-AzureADUser -UserId $user
        }
        $ResultCAPolicy | Add-Member Noteproperty "C_UsersExclude" ($ExcludeUsers -join [System.Environment]::NewLine)

        # Group Conditions
        $IncludeGroups = @()
        foreach($group in $CAPolicy.conditions.users.includeGroups){
            $IncludeGroups += (Invoke-DocGraph -Path "/groups/$($group)").displayName
        }
        $ResultCAPolicy | Add-Member Noteproperty "C_UsersIncludeGroups" ($IncludeGroups -join [System.Environment]::NewLine)

        $ExcludeApps = @()
        foreach($group in $CAPolicy.conditions.users.excludeGroups){
            $ExcludeGroups += (Invoke-DocGraph -Path "/groups/$($group)").displayName
        }
        $ResultCAPolicy | Add-Member Noteproperty "C_UsersExcludeGroups" ($ExcludeGroups -join [System.Environment]::NewLine)

        # Role Conditions
        $IncludeRoles = @()
        foreach($role in $CAPolicy.conditions.users.includeRoles){
            $IncludeRoles += Get-AzureADRole -RoleId $role
        }
        $ResultCAPolicy | Add-Member Noteproperty "C_UsersIncludeRoles" ($IncludeRoles -join [System.Environment]::NewLine)

        $ExcludeApps = @()
        foreach($role in $CAPolicy.conditions.users.excludeRoles){
            $ExcludeRoles += Get-AzureADRole -RoleId $role
        }
        $ResultCAPolicy | Add-Member Noteproperty "C_UsersExcludeRoles" ($ExcludeRoles -join [System.Environment]::NewLine)

        $ResultCAPolicy | Add-Member Noteproperty "G_Operator" $CAPolicy.grantControls.operator
        $ResultCAPolicy | Add-Member Noteproperty "G_BuiltInControls" ($CAPolicy.grantControls.builtInControls -join ",")
        $ResultCAPolicy | Add-Member Noteproperty "G_CustomControls" ($CAPolicy.grantControls.customAuthenticationFactors -join ",")
        $ResultCAPolicy | Add-Member Noteproperty "G_TermsOfUse" ($CAPolicy.grantControls.termsOfUse -join ",")
        $ResultCAPolicy | Add-Member Noteproperty "S_ApplicationEnforcedRestriction" ($CAPolicy.sessionControls.applicationEnforcedRestrictions.isEnabled)
        $ResultCAPolicy | Add-Member Noteproperty "S_CloudAppSecurity" ($CAPolicy.sessionControls.cloudAppSecurity.isEnabled)
        $ResultCAPolicy | Add-Member Noteproperty "S_CloudAppSecurityType" ($CAPolicy.sessionControls.cloudAppSecurity.cloudAppSecurityTyp)
        $ResultCAPolicy | Add-Member Noteproperty "S_PersistentBrowser" ($CAPolicy.sessionControls.persistentBrowser.isEnabled)
        $ResultCAPolicy | Add-Member Noteproperty "S_PersistentBrowserMode" ($CAPolicy.sessionControls.persistentBrowser.mode)
        $ResultCAPolicy | Add-Member Noteproperty "S_SignInFrequency" ($CAPolicy.sessionControls.signInFrequency.isEnabled)
        $ResultCAPolicy | Add-Member Noteproperty "S_SignInFrequencyTimeframe" ("" + $CAPolicy.sessionControls.signInFrequency.value +" "+ $CAPolicy.sessionControls.signInFrequency.type)
        
      

        $DocSecSingle1 = New-Object DocSection
        $DocSecSingle1.Title = "Metadata"
        $ht2 = @{}
        $ResultCAPolicy.psobject.properties | Where-Object { $_.Name -like "M_*" } | ForEach-Object { $ht2[($_.Name.Replace("M_",""))] = ($(if($null -eq $_.Value){""}else{$_.Value})) }
        $DocSecSingle1.Objects = ($ht2.GetEnumerator() | Sort-Object -Property Name | Select-Object Name,Value)
        $DocSecSingle.SubSections += $DocSecSingle1


        $DocSecSingle2 = New-Object DocSection
        $DocSecSingle2.Title = "Conditions"
        $ht2 = @{}
        $ResultCAPolicy.psobject.properties | Where-Object { $_.Name -like "C_*" } | ForEach-Object { $ht2[($_.Name.Replace("C_",""))] = ($(if($null -eq $_.Value){""}else{$_.Value})) }
        $DocSecSingle2.Objects = ($ht2.GetEnumerator() | Sort-Object -Property Name | Select-Object Name,Value)
        $DocSecSingle.SubSections += $DocSecSingle2


        $DocSecSingle3 = New-Object DocSection
        $DocSecSingle3.Title = "Grant Controls"
        $ht2 = @{}
        $ResultCAPolicy.psobject.properties | Where-Object { $_.Name -like "G_*" } | ForEach-Object { $ht2[($_.Name.Replace("G_",""))] = ($(if($null -eq $_.Value){""}else{$_.Value})) }
        $DocSecSingle3.Objects = ($ht2.GetEnumerator() | Sort-Object -Property Name | Select-Object Name,Value)
        $DocSecSingle.SubSections += $DocSecSingle3

        $DocSecSingle4 = New-Object DocSection
        $DocSecSingle4.Title = "Session Controls"
        $ht2 = @{}
        $ResultCAPolicy.psobject.properties | Where-Object { $_.Name -like "S_*" } | ForEach-Object { $ht2[($_.Name.Replace("S_",""))] = ($(if($null -eq $_.Value){""}else{$_.Value})) }
        $DocSecSingle4.Objects = ($ht2.GetEnumerator() | Sort-Object -Property Name | Select-Object Name,Value)
        $DocSecSingle.SubSections += $DocSecSingle4

        $ReturnObj += $DocSecSingle
    } 
    $DocSec.SubSections = $ReturnObj

    return $DocSec
}