Function New-M365DocAppRegistration(){
    <#
    .DESCRIPTION
    This script will create an App registration (WPNinjas.eu Automatic Documentation) in Azure AD. Global Admin privileges are required during execution of this function. Afterwards the created clint secret can be used to execute the Intunde Documentation silently. 

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
    Write-Log "Start Script $Scriptname"

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
    
    
    $appPermissionsRequired = @("AccessReview.Read.All","Agreement.Read.All","AppCatalog.Read.All","Application.Read.All","CloudPC.Read.All","ConsentRequest.Read.All","Device.Read.All","DeviceManagementApps.Read.All","DeviceManagementConfiguration.Read.All","DeviceManagementManagedDevices.Read.All","DeviceManagementRBAC.Read.All","DeviceManagementServiceConfig.Read.All","Directory.Read.All","Domain.Read.All","Organization.Read.All","Policy.Read.All","Policy.ReadWrite.AuthenticationMethod","Policy.ReadWrite.FeatureRollout","PrintConnector.Read.All","Printer.Read.All","PrinterShare.Read.All","PrintSettings.Read.All","PrivilegedAccess.Read.AzureAD","PrivilegedAccess.Read.AzureADGroup","PrivilegedAccess.Read.AzureResources","User.Read" ,"IdentityProvider.Read.All","InformationProtectionPolicy.Read.All"   )
    $targetServicePrincipalName = 'Microsoft Graph'
    $context = "Application"
    $appPermissionsRequiredResolved = Find-MgGraphPermission | Select-Object Name, PermissionType, Id | Where-Object { $_.Name -in $appPermissionsRequired } | Sort -Property Name
        

    if (!(Get-MgApplication | Where-Object {$_.DisplayName -eq $displayName})) {
        $app = New-MgApplication -DisplayName $displayName -SignInAudience "AzureADMyOrg" -Web @{ RedirectUris="urn:ietf:wg:oauth:2.0:oob"; }
        $RequiredResourceAccessArray = @()
        $permissions = $appPermissionsRequiredResolved | ForEach-Object {
            if($_.PermissionType -eq "Application"){
                $t = "Role"
            } else {
                $t = "Scope"
            }
            $RequiredResourceAccessArray += 
                    @{
                        Id = $_.Id
                        Type = $t
                    }
                
            }
        
        Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess @{
            ResourceAppId = "00000003-0000-0000-c000-000000000000"
            ResourceAccess = $RequiredResourceAccessArray
        }
        # create SPN for App Registration
        Write-Debug ('Creating SPN for App Registration {0}' -f $displayName)

        $graphSpId = $(Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'").Id
        $sp = New-MgServicePrincipal -AppId $app.appId
        
        
        $permissions | ForEach-Object {
            New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -AppRoleId $_.Id -ResourceId $graphSpId
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
    Write-Log -Type Warn -Message "Please close the Powershell session and reopen it. Otherwise the connection may fail."
    Write-Log "End Script $Scriptname"
    #endregion
}