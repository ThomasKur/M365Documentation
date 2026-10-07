Function New-M365DocAppRegistration(){
    <#
    .DESCRIPTION
    This script will create an App registration (WPNinjas.eu Automatic Documentation) in Azure AD. Global Admin privileges are required during execution of this function. Afterwards the created client secret can be used to execute the documentation silently.
    Both Microsoft Graph delegated and application permissions are requested when available.
    Application roles are granted for app-only authentication; delegated permissions require separate consent.
    Existing registrations are not updated. For registrations created before 3.7.0, add and grant admin consent for
    User.Read.All, AuditLog.Read.All and Policy.Read.PermissionGrant as application permissions.
    Permissions that resolve only as delegated are reported and cannot be used by app-only tokens.
    Acquire a new token after granting consent.

    .EXAMPLE
    $p = New-M365DocAppRegistration
    $p | fl

    ClientID               : d5cf6364-82f7-4024-9ac1-73a9fd2a6ec3
    ClientSecret           : S03AESdMlhLQIPYYw/cYtLkGkQS0H49jXh02AS6Ek0U=
    ClientSecretExpiration : 21.07.2025 21:39:02
    TenantId               : d873f16a-73a2-4ccf-9d36-67b8243ab99a

    .NOTES
    Author: Thomas Kurth/baseVISION
    Date:   21.7.2020

    History
        See Release Notes in Github.

    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    Param(
        [string]
        $displayName = "WPNinjas.eu Automatic Documentation Custom"
    )
    

    #region Initialization
    ########################################################

    $AzureAD = Get-Module -Name Microsoft.Graph.Authentication
    if($AzureAD){
        Write-Verbose -Message "Microsoft.Graph.Authentication module is loaded."
    } else {
        Write-Warning -Message "Microsoft.Graph.Authentication module is not loaded, please install by 'Install-Module Microsoft.Graph.Authentication'."
    }
    $AzureAD2 = Get-Module -Name Microsoft.Graph.Applications
    if($AzureAD2){
        Write-Verbose -Message "Microsoft.Graph.Applications module is loaded."
    } else {
        Write-Warning -Message "Microsoft.Graph.Applications module is not loaded, please install by 'Install-Module Microsoft.Graph.Applications'."
    }

    #region Authentication
    try{
        Get-MgContract -ErrorAction Stop | Out-Null
    } catch {
        Connect-MgGraph -Scopes "Application.ReadWrite.All"
    }
    #endregion
    #region Main Script
    ########################################################
    
    
    $appPermissionsRequired = @("AccessReview.Read.All","Agreement.Read.All","AppCatalog.Read.All","Application.Read.All","AuditLog.Read.All","CloudPC.Read.All","ConsentRequest.Read.All","Device.Read.All","DeviceManagementApps.Read.All","DeviceManagementConfiguration.Read.All","DeviceManagementManagedDevices.Read.All","DeviceManagementRBAC.Read.All","DeviceManagementServiceConfig.Read.All","Directory.Read.All","Domain.Read.All","EntitlementManagement.Read.All","Organization.Read.All","Policy.Read.All","Policy.Read.PermissionGrant","Policy.ReadWrite.AuthenticationMethod","Policy.ReadWrite.FeatureRollout","PrintConnector.Read.All","Printer.Read.All","PrinterShare.Read.All","PrintSettings.Read.All","PrivilegedAccess.Read.AzureAD","PrivilegedAccess.Read.AzureADGroup","PrivilegedAccess.Read.AzureResources","User.Read.All" ,"IdentityProvider.Read.All","InformationProtectionPolicy.Read","InformationProtectionPolicy.Read.All","PrivilegedEligibilitySchedule.Read.AzureADGroup","RoleEligibilitySchedule.Read.Directory"  )
    $appPermissionsRequiredResolved = @(Find-MgGraphPermission -All -PermissionType Any -Online -ErrorAction Stop | Select-Object Name, PermissionType, Id | Where-Object { $_.Name -in $appPermissionsRequired } | Sort-Object -Property Name)
    $missingPermissions = @($appPermissionsRequired | Where-Object { $_ -notin $appPermissionsRequiredResolved.Name })
    if($missingPermissions.Count -gt 0){
        throw "Unable to resolve required Microsoft Graph permissions: $($missingPermissions -join ', '). Update Microsoft.Graph.Authentication and retry."
    }
    $applicationPermissions = @($appPermissionsRequiredResolved | Where-Object { $_.PermissionType -eq "Application" })
    $delegatedOnlyPermissions = @($appPermissionsRequired | Where-Object { $_ -notin $applicationPermissions.Name })
    if($delegatedOnlyPermissions.Count -gt 0){
        Write-Warning "The following Microsoft Graph permissions resolved only as delegated: $($delegatedOnlyPermissions -join ', '). App-only tokens cannot use these permissions."
    }
        

    if (!(Get-MgApplication | Where-Object {$_.DisplayName -eq $displayName})) {
        $app = New-MgApplication -DisplayName $displayName -SignInAudience "AzureADMyOrg" -Web @{ RedirectUris="urn:ietf:wg:oauth:2.0:oob"; }
        $RequiredResourceAccessArray = @($appPermissionsRequiredResolved | ForEach-Object {
            $permissionType = if($_.PermissionType -eq "Application"){ "Role" } else { "Scope" }
            @{
                Id = $_.Id
                Type = $permissionType
            }
        })
        
        Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess @{
            ResourceAppId = "00000003-0000-0000-c000-000000000000"
            ResourceAccess = $RequiredResourceAccessArray
        }
        # create SPN for App Registration
        Write-Debug ('Creating SPN for App Registration {0}' -f $displayName)

        $graphSpId = $(Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'").Id
        $sp = New-MgServicePrincipal -AppId $app.appId
        
        
        $applicationPermissions | ForEach-Object {
            New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -AppRoleId $_.Id -ResourceId $graphSpId -ErrorAction Stop
        }

        # create a password (spn key)
        $cred = Add-MgApplicationPassword -ApplicationId $app.id


    } else {
        Write-Debug ('App Registration {0} already exists' -f $displayName)
    }

    
    

    #endregion
    #region Finishing
    ########################################################
    [PSCustomObject]@{
        ClientID = $app.AppId
        ClientSecret = $cred.secretText
        ClientSecretExpiration = $cred.EndDateTime
        TenantId = $($(Get-MgContext).TenantId)
    }
    Write-Warning "Please close the Powershell session and reopen it. Otherwise the connection may fail."
    #endregion
}