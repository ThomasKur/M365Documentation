#Requires -Modules Pester

# MSAL.PS is needed only for the MSAL-based sign-in paths, not when a caller supplies a raw token.

BeforeAll {
    $script:manifest = [System.IO.Path]::GetFullPath("$PSScriptRoot/../M365Documentation/M365Documentation.psd1")
}

Describe 'MSAL.PS is optional for raw-token use' {

    It 'is not a required module in the manifest' {
        $required = (Import-PowerShellDataFile -Path $script:manifest).RequiredModules |
            ForEach-Object { if ($_ -is [hashtable]) { $_.ModuleName } else { $_ } }
        $required | Should -Not -Contain 'MSAL.PS'
        $required | Should -Contain 'PSWriteOffice'
    }

    It 'imports the module and connects with -AccessToken without loading MSAL.PS' {
        $probe = "Import-Module '$script:manifest' -WarningAction SilentlyContinue; " +
            "Connect-M365Doc -AccessToken 'raw-bearer' -TokenExpiresOn (Get-Date).AddMinutes(5); " +
            "[bool](Get-Module -Name MSAL.PS)"
        $output = & pwsh -NoProfile -NonInteractive -Command $probe
        $LASTEXITCODE | Should -Be 0
        ($output | Select-Object -Last 1) | Should -Be 'False'
    }
}
