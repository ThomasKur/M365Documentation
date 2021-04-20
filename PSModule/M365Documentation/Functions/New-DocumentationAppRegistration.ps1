Function New-DocumentationAppRegistration(){
    <#
    .DESCRIPTION
    This script will create an App registration(WPNinjas.eu Automatic Documentation) in Azure AD. Global Admin privileges are required during execution of this function. Afterwards the created clint secret can be used to execute the Intunde Documentation silently. 

    .EXAMPLE
    $p = New-DocumentationAppRegistration
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
        [int]
        $TokenLifetimeDays = 365
    )
    ## Manual Variable Definition
    ########################################################
    #$DebugPreference = "Continue"
    $ScriptName = "DocumentIntuneAppRegistration"
    

    #region Initialization
    ########################################################
    Write-Log "Start Script $Scriptname"

    $AzureAD = Get-Module -Name AzureAD
    if($AzureAD){
        Write-Verbose -Message "AzureAD module is loaded."
    } else {
        Write-Warning -Message "AzureAD module is not loaded, please install by 'Install-Module AzureAD'."
    }

    #region Authentication
    Connect-AzureAD | Out-Null
    #endregion
    #region Main Script
    ########################################################
    
    $displayName = "WPNinjas.eu Automatic Documentation"
    $appPermissionsRequired = @('Policy.Read.All',
                                    'Directory.Read.All',
                                    'DeviceManagementServiceConfig.Read.All',
                                    'DeviceManagementRBAC.Read.All',
                                    'DeviceManagementManagedDevices.Read.All',
                                    'DeviceManagementConfiguration.Read.All',
                                    'DeviceManagementApps.Read.All',
                                    'Device.Read.All',
                                    'Agreement.Read.All',
                                    'Application.Read.All')
    $targetServicePrincipalName = 'Microsoft Graph'

    if (!(Get-AzureADApplication -SearchString $displayName)) {
        $app = New-AzureADApplication -DisplayName $displayName `
            -Homepage "https://www.wpninjas.eu" `
            -ReplyUrls "urn:ietf:wg:oauth:2.0:oob" `
            -PublicClient $true


        # create SPN for App Registration
        Write-Debug ('Creating SPN for App Registration {0}' -f $displayName)

        # create a password (spn key)
        $startDate = Get-Date
        $endDate = $startDate.AddDays($TokenLifetimeDays)
        $appPwd = New-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId -CustomKeyIdentifier ((New-Guid).Guid.Replace("-","").subString(0, 30)) -StartDate $startDate -EndDate $endDate

        # create a service principal for your application
        # you need this to be able to grant your application the required permission
        $spForApp = New-AzureADServicePrincipal -AppId $app.AppId -PasswordCredentials @($appPwd)
        Set-AzureADAppPermission -targetServicePrincipalName $targetServicePrincipalName -appPermissionsRequired $appPermissionsRequired -childApp $app -spForApp $spForApp
    
    } else {
        Write-Debug ('App Registration {0} already exists' -f $displayName)
        $app = Get-AzureADApplication -SearchString $displayName
        $spForApp = Get-AzureADServicePrincipal -SearchString $app.AppId
        # create a password (spn key)
        $startDate = Get-Date
        $endDate = $startDate.AddDays($TokenLifetimeDays)
        $appPwd = New-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId -CustomKeyIdentifier ((New-Guid).Guid.Replace("-","").subString(0, 30)) -StartDate $startDate -EndDate $endDate
        Set-AzureADAppPermission -targetServicePrincipalName $targetServicePrincipalName -appPermissionsRequired $appPermissionsRequired -childApp $app -spForApp $spForApp -ErrorAction SilentlyContinue
    
    }

    
    

    #endregion
    #region Finishing
    ########################################################
    [PSCustomObject]@{
        ClientID = $app.AppId
        ClientSecret = $appPwd.Value
        ClientSecretExpiration = $appPwd.EndDate
        TenantId = (Get-AzureADCurrentSessionInfo).TenantId
    }

    Write-Log "End Script $Scriptname"
    #endregion
}