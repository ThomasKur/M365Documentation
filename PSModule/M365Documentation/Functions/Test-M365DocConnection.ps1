function Test-M365DocConnection {
<#
.SYNOPSIS
  Quick sanity check for the current M365Documentation connection.

.DESCRIPTION
  Calls /organization using Invoke-DocGraph and returns a small status object:
  Cloud, BaseUrl, Token expiry, and the Org Id/DisplayName.

.PARAMETER Beta
  Use the Graph beta endpoint instead of v1.0.
#>
  [CmdletBinding()]
  param([switch]$Beta)

  # Basic prereq checks
  if (-not $script:token) { throw "Not connected. Run Connect-M365Doc first." }
  if (-not $script:M365Doc_GraphBase) { throw "Graph base not set. Connect-M365Doc should set M365Doc_GraphBase." }

  # Make sure we have a fresh token and normalized base URL
  try { Test-TokenExpiration } catch { Write-Verbose "Test-TokenExpiration not found or failed: $($_.Exception.Message)" }
  $base = $script:M365Doc_GraphBase
  if ($base[-1] -ne '/') { $base += '/' }

  # Probe the tenant
  $resp = Invoke-DocGraph -Path "/organization" -Beta:$Beta
  $org  = if ($resp.value) { $resp.value | Select-Object -First 1 } else { $resp }

  [pscustomobject]@{
    CloudEnvironment = $script:M365Doc_CloudEnvironment
    BaseUrl          = $base
    UsingBeta        = [bool]$Beta
    TokenExpires     = $script:token.ExpiresOn.LocalDateTime
    OrganizationId   = $org.id
    OrganizationName = $org.displayName
  }
}
