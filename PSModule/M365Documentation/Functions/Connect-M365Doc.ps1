function Connect-M365Doc {
<#
.SYNOPSIS
  Connects M365Documentation to Microsoft Graph and sets cloud-specific endpoints.

.DESCRIPTION
  Uses MSAL.PS to acquire a token for Microsoft Graph. Supports Commercial, USGov (GCC High),
  and USGovDoD. Publishes script-scoped variables used elsewhere in the module (Graph base/v1/beta and
  the Authorization header). Secret-first auth; if no secret is supplied (or -UseInteractive is set),
  it falls back to interactive.

.PARAMETER CloudEnvironment
  Commercial | USGov | USGovDoD (default: Commercial)

.PARAMETER TenantId
  Your Azure AD tenant ID (GUID). If omitted and -PromptIfMissing, will prompt.

.PARAMETER ClientId
  Application (client) ID. For secret flow: confidential client. For interactive: public client
  with http://localhost redirect and public client flows enabled. If omitted and -PromptIfMissing, will prompt.

.PARAMETER ClientSecret
  SecureString app secret for confidential client auth. If omitted (and not forcing secret),
  we fall back to interactive.

.PARAMETER UseInteractive
  Force interactive sign-in even if a secret is provided.

.PARAMETER PromptIfMissing
  If set (default), the function will prompt for missing TenantId/ClientId.
#>

  [CmdletBinding()]
  param(
    [ValidateSet('Commercial','USGov','USGovDoD')]
    [string] $CloudEnvironment = 'Commercial',

    [string] $TenantId,
    [string] $ClientId,

    [SecureString] $ClientSecret,

    [switch] $UseInteractive,
    [switch] $PromptIfMissing = $true
  )

  # ---------- Helper: GUID validator ----------
  function _IsGuid([string]$s) {
    return [Guid]::TryParse($s, [ref]([Guid]::Empty))
  }

  # ---------- Prompt for missing IDs (optional) ----------
  if ($PromptIfMissing) {
    if (-not $TenantId)   { $TenantId  = Read-Host "Enter TenantId (GUID)" }
    if (-not $ClientId)   { $ClientId  = Read-Host "Enter ClientId (App registration ID)" }
  }

  # ---------- Validate IDs if provided ----------
  if (-not (_IsGuid $TenantId)) { throw "TenantId is required and must be a valid GUID." }
  if (-not (_IsGuid $ClientId)) { throw "ClientId is required and must be a valid GUID." }

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
  $script:M365Doc_GraphV1          = ($GraphBase + 'v1.0/')
  $script:M365Doc_GraphBeta        = ($GraphBase + 'beta/')

  # Decide auth path
  $useSecret = $PSBoundParameters.ContainsKey('ClientSecret') -and -not $UseInteractive
  Write-Host ("Connecting to Microsoft Graph: Env={0}, Tenant={1}, Mode={2}" -f `
              $CloudEnvironment, $TenantId, ($useSecret ? 'Confidential (secret)' : 'Interactive')) -ForegroundColor Cyan

  # ---------- Acquire token via MSAL.PS ----------
  try {
    if ($useSecret) {
      # Confidential client (app secret)
      $token = Get-MsalToken -TenantId     $TenantId `
                             -ClientId     $ClientId `
                             -ClientSecret $ClientSecret `
                             -Authority    "$AuthorityHost/$TenantId" `
                             -Scopes       $GraphScope
    } else {
      # Interactive / public client (your own public app with http://localhost redirect)
      $token = Get-MsalToken -TenantId   $TenantId `
                             -ClientId   $ClientId `
                             -Authority  "$AuthorityHost/$TenantId" `
                             -Scopes     $GraphScope `
                             -RedirectUri 'http://localhost'
    }

    if (-not $token -or -not $token.AccessToken) {
      throw "Failed to obtain access token."
    }

    # Store token + header where other functions can use them
    $script:token = $token
    $script:M365Doc_AuthorizationHeader = @{ Authorization = "Bearer $($token.AccessToken)" }

    Write-Host ("Connected. Token expires at {0}." -f $token.ExpiresOn.LocalDateTime) -ForegroundColor Green
    Write-Verbose "Graph base: $($script:M365Doc_GraphBase)"
  }
  catch {
    Write-Error "Connect-M365Doc failed: $($_.Exception.Message)"
    throw
  }
}
