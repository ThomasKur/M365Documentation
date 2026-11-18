#Requires -Modules Pester

# Validates the RawToken parameter set of Connect-M365Doc.

BeforeAll {
    # Shim the MSAL.PS type so the function definition parses when MSAL.PS
    # is not installed in the test environment. The RawToken parameter set
    # under test does not depend on this type, but PowerShell parses the
    # entire param block when the function is dot-sourced.
    if (-not ([System.Management.Automation.PSTypeName]'Microsoft.Identity.Client.AuthenticationResult').Type) {
        Add-Type -TypeDefinition @'
namespace Microsoft.Identity.Client {
    public class AuthenticationResult {
        public string AccessToken { get; set; }
        public System.DateTimeOffset ExpiresOn { get; set; }
    }
}
'@
    }

    $here = Split-Path -Parent $PSCommandPath
    $modulePath = Join-Path (Split-Path -Parent $here) 'M365Documentation'
    $functionPath = Join-Path $modulePath 'Functions/Connect-M365Doc.ps1'
    . $functionPath
}

Describe 'Connect-M365Doc -AccessToken (RawToken parameter set)' {

    It 'Accepts a non-empty bearer token and a future expiry' {
        $expires = (Get-Date).AddMinutes(30)
        { Connect-M365Doc -AccessToken 'eyJhbGciOiJSUzI1NiJ9.stub.stub' -TokenExpiresOn $expires } |
            Should -Not -Throw
    }

    It 'Populates $script:token.AccessToken with the raw string' {
        $expires = (Get-Date).AddMinutes(30)
        Connect-M365Doc -AccessToken 'raw-bearer-value' -TokenExpiresOn $expires
        $script:token.AccessToken | Should -Be 'raw-bearer-value'
    }

    It 'Populates $script:token.ExpiresOn.LocalDateTime' {
        $expires = (Get-Date).AddMinutes(30)
        Connect-M365Doc -AccessToken 'raw-bearer-value' -TokenExpiresOn $expires
        $script:token.ExpiresOn.LocalDateTime | Should -Be $expires
    }

    It 'Errors when the token is already expired' {
        $past = (Get-Date).AddMinutes(-5)
        # Write-Error surfaces via -ErrorAction Stop as a terminating error.
        { Connect-M365Doc -AccessToken 'raw' -TokenExpiresOn $past -ErrorAction Stop } |
            Should -Throw
    }

    It 'Rejects an empty AccessToken' {
        { Connect-M365Doc -AccessToken '' -TokenExpiresOn (Get-Date).AddMinutes(30) } |
            Should -Throw
    }

    It 'Defaults TokenExpiresOn to 55 minutes from now when omitted' {
        Connect-M365Doc -AccessToken 'raw-bearer-value'
        $delta = $script:token.ExpiresOn.LocalDateTime - (Get-Date)
        $delta.TotalMinutes | Should -BeGreaterThan 50
        $delta.TotalMinutes | Should -BeLessThan 60
    }
}
