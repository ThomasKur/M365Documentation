BeforeAll {
    . "$PSScriptRoot\..\M365Documentation\Functions\New-M365DocAppRegistration.ps1"

    function Get-MgContract { [CmdletBinding()] param() }
    function Connect-MgGraph { param($Scopes) }
    function Find-MgGraphPermission { [CmdletBinding()] param([switch]$All, $PermissionType, [switch]$Online) }
    function Get-MgApplication {}
    function New-MgApplication { param($DisplayName, $SignInAudience, $Web) }
    function Update-MgApplication { param($ApplicationId, $RequiredResourceAccess) }
    function Get-MgServicePrincipal { param($Filter) }
    function New-MgServicePrincipal { param($AppId) }
    function New-MgServicePrincipalAppRoleAssignment {
        [CmdletBinding()]
        param($ServicePrincipalId, $PrincipalId, $AppRoleId, $ResourceId)
    }
    function Add-MgApplicationPassword { param($ApplicationId) }
    function Get-MgContext {}

    $script:requiredNames = @(
        'AccessReview.Read.All', 'Agreement.Read.All', 'AppCatalog.Read.All', 'Application.Read.All',
        'AuditLog.Read.All', 'CloudPC.Read.All', 'ConsentRequest.Read.All', 'Device.Read.All',
        'DeviceManagementApps.Read.All', 'DeviceManagementConfiguration.Read.All',
        'DeviceManagementManagedDevices.Read.All', 'DeviceManagementRBAC.Read.All',
        'DeviceManagementServiceConfig.Read.All', 'Directory.Read.All', 'Domain.Read.All',
        'EntitlementManagement.Read.All', 'Organization.Read.All', 'Policy.Read.All',
        'Policy.Read.PermissionGrant', 'Policy.ReadWrite.AuthenticationMethod', 'Policy.ReadWrite.FeatureRollout',
        'PrintConnector.Read.All', 'Printer.Read.All', 'PrinterShare.Read.All', 'PrintSettings.Read.All',
        'PrivilegedAccess.Read.AzureAD', 'PrivilegedAccess.Read.AzureADGroup', 'PrivilegedAccess.Read.AzureResources',
        'User.Read.All', 'IdentityProvider.Read.All', 'InformationProtectionPolicy.Read', 'InformationProtectionPolicy.Read.All',
        'PrivilegedEligibilitySchedule.Read.AzureADGroup', 'RoleEligibilitySchedule.Read.Directory'
    )
    $script:applicationPermissions = @($script:requiredNames | ForEach-Object {
        [pscustomobject]@{ Name = $_; PermissionType = 'Application'; Id = [guid]::NewGuid().ToString() }
    })
    $script:delegatedPermissions = @($script:requiredNames + 'User.Read' | ForEach-Object {
        [pscustomobject]@{ Name = $_; PermissionType = 'Delegated'; Id = [guid]::NewGuid().ToString() }
    })
}

Describe 'New-M365DocAppRegistration permissions' {
    BeforeEach {
        $script:resolvedPermissions = $script:applicationPermissions + $script:delegatedPermissions
        Mock Get-Module { [pscustomobject]@{ Name = $Name } }
        Mock Get-MgContract {}
        Mock Connect-MgGraph {}
        Mock Find-MgGraphPermission { $script:resolvedPermissions }
        Mock Get-MgApplication {}
        Mock New-MgApplication { [pscustomobject]@{ Id = 'application-object'; AppId = 'application-client' } }
        Mock Update-MgApplication {}
        Mock Get-MgServicePrincipal { [pscustomobject]@{ Id = 'graph-service-principal' } }
        Mock New-MgServicePrincipal { [pscustomobject]@{ Id = 'application-service-principal' } }
        Mock New-MgServicePrincipalAppRoleAssignment {}
        Mock Add-MgApplicationPassword {
            [pscustomobject]@{ SecretText = 'test-secret'; EndDateTime = [datetime]'2027-01-01' }
        }
        Mock Get-MgContext { [pscustomobject]@{ TenantId = 'tenant-id' } }
        Mock Write-Warning {}
    }

    It 'requests both permission types but grants consent only for application roles' {
        $result = New-M365DocAppRegistration

        Should -Invoke Find-MgGraphPermission -Times 1 -Exactly -ParameterFilter {
            $All -and $Online -and $PermissionType -eq 'Any' -and $ErrorAction -eq 'Stop'
        }
        Should -Invoke Update-MgApplication -Times 1 -Exactly -ParameterFilter {
            $access = @($RequiredResourceAccess.ResourceAccess)
            $ApplicationId -eq 'application-object' -and
            $RequiredResourceAccess.ResourceAppId -eq '00000003-0000-0000-c000-000000000000' -and
            $access.Count -eq (2 * $script:requiredNames.Count) -and
            @($access | Where-Object { $_.Type -eq 'Role' }).Count -eq $script:requiredNames.Count -and
            @($access | Where-Object { $_.Type -eq 'Scope' }).Count -eq $script:requiredNames.Count -and
            @(Compare-Object (@($access | Where-Object Type -eq 'Role').Id | Sort-Object) ($script:applicationPermissions.Id | Sort-Object)).Count -eq 0 -and
            @(Compare-Object (@($access | Where-Object Type -eq 'Scope').Id | Sort-Object) (@($script:delegatedPermissions | Where-Object Name -in $script:requiredNames).Id | Sort-Object)).Count -eq 0
        }
        Should -Invoke New-MgServicePrincipalAppRoleAssignment -Times $script:requiredNames.Count -Exactly
        foreach ($permission in $script:applicationPermissions) {
            Should -Invoke New-MgServicePrincipalAppRoleAssignment -Times 1 -Exactly -ParameterFilter {
                $AppRoleId -eq $permission.Id -and
                $ServicePrincipalId -eq 'application-service-principal' -and
                $PrincipalId -eq 'application-service-principal' -and
                $ResourceId -eq 'graph-service-principal' -and
                $ErrorAction -eq 'Stop'
            }
        }
        $result.ClientID | Should -Be 'application-client'
        $result.ClientSecret | Should -Be 'test-secret'
        $result.ClientSecretExpiration | Should -Be ([datetime]'2027-01-01')
        $result.TenantId | Should -Be 'tenant-id'
    }

    It 'accepts application permissions without a delegated counterpart' {
        $script:resolvedPermissions = $script:applicationPermissions

        New-M365DocAppRegistration | Out-Null

        Should -Invoke Update-MgApplication -Times 1 -Exactly -ParameterFilter {
            @($RequiredResourceAccess.ResourceAccess).Count -eq $script:requiredNames.Count -and
            @($RequiredResourceAccess.ResourceAccess | Where-Object Type -ne 'Role').Count -eq 0
        }
        Should -Invoke Write-Warning -Times 0 -Exactly -ParameterFilter {
            $Message -like '*resolved only as delegated*'
        }
        Should -Invoke New-MgServicePrincipalAppRoleAssignment -Times $script:requiredNames.Count -Exactly
    }

    It 'fails before creating an app when <Name> cannot be resolved' -ForEach @(
        @{ Name = 'User.Read.All' }
        @{ Name = 'AuditLog.Read.All' }
        @{ Name = 'Policy.Read.PermissionGrant' }
        @{ Name = 'CloudPC.Read.All' }
        @{ Name = 'PrinterShare.Read.All' }
        @{ Name = 'Agreement.Read.All' }
        @{ Name = 'InformationProtectionPolicy.Read' }
    ) {
        $script:resolvedPermissions = @($script:resolvedPermissions | Where-Object {
            $_.Name -ne $Name
        })

        { New-M365DocAppRegistration } | Should -Throw "*Unable to resolve required Microsoft Graph permissions: $Name.*"
        Should -Invoke New-MgApplication -Times 0 -Exactly
        Should -Invoke Update-MgApplication -Times 0 -Exactly
        Should -Invoke New-MgServicePrincipalAppRoleAssignment -Times 0 -Exactly
    }

    It 'warns about delegated-only <Name> without trying to grant it as an application role' -ForEach @(
        @{ Name = 'PrinterShare.Read.All' }
        @{ Name = 'InformationProtectionPolicy.Read' }
    ) {
        $script:resolvedPermissions = @($script:resolvedPermissions | Where-Object {
            $_.Name -ne $Name -or $_.PermissionType -ne 'Application'
        })

        $result = New-M365DocAppRegistration

        $result.ClientID | Should -Be 'application-client'
        Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter {
            $Message -eq "The following Microsoft Graph permissions resolved only as delegated: $Name. App-only tokens cannot use these permissions."
        }
        Should -Invoke New-MgServicePrincipalAppRoleAssignment -Times ($script:requiredNames.Count - 1) -Exactly
        Should -Invoke New-MgServicePrincipalAppRoleAssignment -Times 0 -Exactly -ParameterFilter {
            $AppRoleId -in $script:delegatedPermissions.Id
        }
        Should -Invoke Update-MgApplication -Times 1 -Exactly -ParameterFilter {
            @($RequiredResourceAccess.ResourceAccess | Where-Object {
                $_.Id -eq ($script:delegatedPermissions | Where-Object Name -eq $Name).Id -and
                $_.Type -eq 'Scope'
            }).Count -eq 1
        }
    }

    It 'propagates permission resolution failures without creating an app' {
        Mock Find-MgGraphPermission { throw 'Permission lookup failed' }

        { New-M365DocAppRegistration } | Should -Throw '*Permission lookup failed*'
        Should -Invoke New-MgApplication -Times 0 -Exactly
    }

    It 'does not return credentials when granting an application role fails' {
        Mock New-MgServicePrincipalAppRoleAssignment { throw 'Consent denied' }

        { New-M365DocAppRegistration } | Should -Throw '*Consent denied*'
        Should -Invoke Add-MgApplicationPassword -Times 0 -Exactly
    }
}
