Function Connect-M365Doc(){
<#
.SYNOPSIS
    Connects M365Documentation to Microsoft Graph and sets cloud-specific endpoints.
.DESCRIPTION
    Uses MSAL.PS to acquire a token for Microsoft Graph. Supports Commercial, USGov (GCC High),
    and USGovDoD.

.PARAMETER token  
    You can pass a token you have aquired seperately via Get-MsalToken. You have to make sure, that this token has all required scopes included.

.PARAMETER ClientID
    The ClientId of your App Registration. You can create the app registration in your tenant by using the New-M365DocAppRegistration command.

.PARAMETER ClientSecret
    The ClientSecret of your App Registration. You can create the app registration in your tenant by using the New-M365DocAppRegistration command.

.PARAMETER TenantId
    The TenantId of your Azure AD Tenant.

.PARAMETER NeverRefreshToken
    By default the token will be refreshed automatically if it is expired. If you set this switch, the token will never be refreshed automatically.
    You can still force a refresh by using the Force parameter.

.PARAMETER Force
    By default the function will check if a valid token is already available and will not request a new one. If you set this switch, a new token will be requested even if a valid token is already available.


 
.EXAMPLE Interactive
    Connect-M365Doc
    Displays authentication prompt and allows you to sign in. 

.EXAMPLE CustomToken
    Connect-M365Doc -token $token

    You can pass a token you have aquired seperately via Get-MsalToken. You have to make sure, that this token has all required scopes included.
.EXAMPLE PublicClient-Silent
    Connect-M365Doc -ClientId '00000000-0000-0000-0000-000000000000' -ClientSecret (ConvertTo-SecureString 'SuperSecretString' -AsPlainText -Force) -TenantId '00000000-0000-0000-0000-000000000000'
    
    Get token based on the submitted information. You can creat the app registration in your tenant by using the New-DocumentationAppRegistration command.
#>
  
  param(
    [CmdletBinding(DefaultParameterSetName = 'Interactive-Custom')]
    [parameter(Mandatory=$true, ParameterSetName='CustomToken')]
    [parameter(Mandatory=$false, ParameterSetName='PublicClient-Silent')]
    [ValidateSet('Commercial','USGov','USGovDoD')]
    [string] $CloudEnvironment = 'Commercial',
    [parameter(Mandatory=$true, ParameterSetName='CustomToken')]
    [Microsoft.Identity.Client.AuthenticationResult]$token,
    [parameter(Mandatory=$true, ParameterSetName='PublicClient-Silent')]
    [CmdletBinding(DefaultParameterSetName = 'Interactive-Custom')]
    [guid]$ClientID,
    [parameter(Mandatory=$true, ParameterSetName='PublicClient-Silent')]
    [Security.SecureString]$ClientSecret,
    [parameter(Mandatory=$true, ParameterSetName='PublicClient-Silent')]
    [CmdletBinding(DefaultParameterSetName = 'Interactive-Custom')]
    [guid]$TenantId,
    [parameter(Mandatory=$false, ParameterSetName='Interactive')]
    [parameter(Mandatory=$false, ParameterSetName='PublicClient-Silent')]
    [switch]$NeverRefreshToken,
    [parameter(Mandatory=$false, ParameterSetName='Interactive')]
    [switch]$Force
  )
  # ---------- Map environment to endpoints ----------
  switch ($CloudEnvironment) {
    'Commercial' { $AuthorityHost='https://login.microsoftonline.com'; $GraphBase='https://graph.microsoft.com/'; }
    'USGov'      { $AuthorityHost='https://login.microsoftonline.us';  $GraphBase='https://graph.microsoft.us/'; }
    'USGovDoD'   { $AuthorityHost='https://login.microsoftonline.us';  $GraphBase='https://dod-graph.microsoft.us/'; }
  }
  $GraphScope = ($GraphBase.TrimEnd('/') + '/.default')

  # Publish for the rest of the module (used by Invoke-DocGraph, etc.)
  $script:M365Doc_CloudEnvironment = $CloudEnvironment
  $script:M365Doc_GraphBase        = $GraphBase

  switch -Wildcard ($PSCmdlet.ParameterSetName) {
      "CustomToken" {
          # Verify token
          if ($token.ExpiresOn.LocalDateTime -le $(Get-Date)) {
              Write-Error "Token expired, please pass a valid and not expired token."
          } elseif($null -eq $token){
              Write-Error "No Token passed as token parameter, please pass a valid and not expired token."
          } else {
              $script:token = $token
          }
          Write-Verbose "Custom Token expires: $($script:token.ExpiresOn.LocalDateTime)"
          break
      }
      "PublicClient-Silent" {
          # Connect to Microsoft Intune PowerShell App
          $script:tokenRequest = @{
              ClientId = $ClientId
              RedirectUri = "msal37f82fa9-674e-4cae-9286-4b21eb9a6389://auth"
              TenantId = $TenantId
              Scopes = $GraphScope
              Authority = "$AuthorityHost/$TenantId"
              ClientSecret = $ClientSecret
              ForceRefresh = $True # We could be pulling a token from the MSAL Cache, ForceRefresh to ensure it's new and has the longest timeline.
          }
          if($NeverRefreshToken) { $script:tokenRequest.ForceRefresh = $False}
          
          $script:token = Get-MsalToken @script:tokenRequest
          
          # Verify token
          if (-not ($script:token -and $script:token.ExpiresOn.LocalDateTime -ge $(Get-Date))) {
              Write-Error "Connection failed."
          }
          Write-Verbose "PublicClient-Silent Token expires: $($script:token.ExpiresOn.LocalDateTime)"
          break
      }
      "Interactive" {
          # Connect to M365 App
          $script:tokenRequest = @{
              ClientId    = "37f82fa9-674e-4cae-9286-4b21eb9a6389"
              RedirectUri = "http://localhost"
              Scopes = $GraphScope
              ForceRefresh = $True # We could be pulling a token from the MSAL Cache, ForceRefresh to ensure it's new and has the longest timeline.
          }

          if($NeverRefreshToken) { $script:tokenRequest.ForceRefresh = $False}

          # Verify token
          if (-not ($script:token -and $script:token.ExpiresOn.LocalDateTime -ge $(Get-Date))) {
              $script:token = Get-MsalToken @script:tokenRequest
          } else {
              if($Force){
                  Write-Information "Force reconnection"
                  $script:token = Get-MsalToken @params
              } else {
                  Write-Information "Already connected."
              }
          }
          Write-Verbose "Interactive Token expires: $($script:token.ExpiresOn.LocalDateTime)"
          break
      }
      "Interactive-Custom" {
          # Connect to M365 App
          $script:tokenRequest = @{
              ClientId    = $ClientID
              TenantId    = $TenantID
              Scopes = $GraphScope
              Authority = "$AuthorityHost/$TenantId"
              RedirectUri = "http://localhost"
              ForceRefresh = $True # We could be pulling a token from the MSAL Cache, ForceRefresh to ensure it's new and has the longest timeline.
          }

          if($NeverRefreshToken) { $script:tokenRequest.ForceRefresh = $False}

          # Verify token
          if (-not ($script:token -and $script:token.ExpiresOn.LocalDateTime -ge $(Get-Date))) {
              $script:token = Get-MsalToken @script:tokenRequest
          } else {
              if($Force){
                  Write-Information "Force reconnection"
                  $script:token = Get-MsalToken @params
              } else {
                  Write-Information "Already connected."
              }
          }
          Write-Verbose "Interactive Token expires: $($script:token.ExpiresOn.LocalDateTime)"
          break
      }
  }
}