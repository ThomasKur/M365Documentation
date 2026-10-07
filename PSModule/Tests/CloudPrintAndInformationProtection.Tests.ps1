BeforeAll {
    $modulePath = "$PSScriptRoot\..\M365Documentation"
    $moduleAst = [System.Management.Automation.Language.Parser]::ParseFile(
        "$modulePath\M365Documentation.psm1", [ref]$null, [ref]$null
    )
    $classDefinitions = $moduleAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.TypeDefinitionAst]
    }, $false) | ForEach-Object { $_.Extent.Text }
    . ([scriptblock]::Create($classDefinitions -join "`n"))
    . "$modulePath\Internal\Collector\CloudPrint\Get-CPPrinter.ps1"
    . "$modulePath\Internal\Collector\InformationProtection\Get-MIPLabel.ps1"

    function Invoke-DocGraph { param($Path, [switch]$Beta) }
    function Test-TokenExpiration {}
}

Describe 'Cloud Print printer subsections' {
    BeforeEach {
        Mock Invoke-DocGraph {
            switch ($Path) {
                '/print/printers' {
                    return [pscustomobject]@{ value = @(
                        [pscustomobject]@{ id = 'printer-1'; displayName = 'First printer' }
                        [pscustomobject]@{ id = 'printer-2'; displayName = 'Second printer' }
                    ) }
                }
                '/print/printers/printer-1/shares' { return [pscustomobject]@{ value = @([pscustomobject]@{ id = 'share-1' }) } }
                '/print/printers/printer-1/connectors' { return [pscustomobject]@{ value = @([pscustomobject]@{ id = 'connector-1' }) } }
                '/print/printers/printer-2/shares' { return [pscustomobject]@{ value = @() } }
                '/print/printers/printer-2/connectors' { return [pscustomobject]@{ value = @() } }
                default { throw "Unexpected Graph path: $Path" }
            }
        }
    }

    It 'returns literal titles and preserves data for multiple printers without command errors' {
        $result = Get-CPPrinter -ErrorAction Stop

        $result.Title | Should -Be 'Printers'
        $result.SubSections.Count | Should -Be 2
        foreach ($printer in $result.SubSections) {
            $printer.SubSections.Count | Should -Be 2
            $printer.SubSections[0].Title | Should -Be 'Shares'
            $printer.SubSections[1].Title | Should -Be 'Connectors'
            $printer.SubSections[0].Transpose | Should -BeFalse
            $printer.SubSections[1].Transpose | Should -BeFalse
        }
        $result.SubSections[0].SubSections[0].Objects[0].id | Should -Be 'share-1'
        $result.SubSections[0].SubSections[1].Objects[0].id | Should -Be 'connector-1'
        $result.SubSections[1].SubSections[0].Objects | Should -BeNullOrEmpty
        $result.SubSections[1].SubSections[1].Objects | Should -BeNullOrEmpty
        Should -Invoke Invoke-DocGraph -Times 1 -Exactly -ParameterFilter { $Path -eq '/print/printers' -and $Beta }
        Should -Invoke Invoke-DocGraph -Times 5 -Exactly
    }

    It 'returns no section when there are no printers' {
        Mock Invoke-DocGraph { [pscustomobject]@{ value = @() } }

        Get-CPPrinter -ErrorAction Stop | Should -BeNullOrEmpty
        Should -Invoke Invoke-DocGraph -Times 1 -Exactly
    }
}

Describe 'Information Protection sensitivity labels' {
    BeforeEach {
        $script:M365Doc_CloudEnvironment = 'Commercial'
        $script:token = [pscustomobject]@{ Account = $null }
        Mock Test-TokenExpiration {}
        Mock Write-Warning {}
        Mock Invoke-DocGraph {
            [pscustomobject]@{ value = @([pscustomobject]@{ id = 'label-1'; name = 'Confidential' }) }
        }
    }

    It 'requests organization labels for app-only authentication' {
        $result = Get-MIPLabel -ErrorAction Stop

        $result.Title | Should -Be 'Labels'
        $result.Objects[0].id | Should -Be 'label-1'
        $result.Transpose | Should -BeFalse
        Should -Invoke Invoke-DocGraph -Times 1 -Exactly -ParameterFilter {
            $Path -eq '/security/informationProtection/sensitivityLabels' -and $Beta
        }
        Should -Invoke Write-Warning -Times 0 -Exactly
    }

    It 'requests user labels and warns about coverage for delegated authentication' {
        $script:token = [pscustomobject]@{ Account = [pscustomobject]@{ Username = 'test@example.com' } }

        $result = Get-MIPLabel -ErrorAction Stop

        $result.Objects[0].name | Should -Be 'Confidential'
        Should -Invoke Invoke-DocGraph -Times 1 -Exactly -ParameterFilter {
            $Path -eq '/me/security/informationProtection/sensitivityLabels' -and $Beta
        }
        Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter {
            $Message -like '*only documents labels available to the signed-in user*'
        }
    }

    It 'uses the current token account after refreshing rather than the connection request' {
        $script:tokenRequest = @{ ClientSecret = 'test-only' }
        Mock Test-TokenExpiration {
            $script:token = [pscustomobject]@{ Account = [pscustomobject]@{ Username = 'test@example.com' } }
        }
        try {
            Get-MIPLabel | Out-Null

            Should -Invoke Test-TokenExpiration -Times 1 -Exactly
            Should -Invoke Invoke-DocGraph -Times 1 -Exactly -ParameterFilter {
                $Path -eq '/me/security/informationProtection/sensitivityLabels' -and $Beta
            }
        } finally {
            $script:tokenRequest = $null
        }
    }

    It 'warns and skips the unsupported <Cloud> cloud without a Graph request' -ForEach @(
        @{ Cloud = 'USGov' }
        @{ Cloud = 'USGovDoD' }
    ) {
        $script:M365Doc_CloudEnvironment = $Cloud

        Get-MIPLabel | Should -BeNullOrEmpty

        Should -Invoke Invoke-DocGraph -Times 0 -Exactly
        Should -Invoke Test-TokenExpiration -Times 0 -Exactly
        Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter {
            $Message -like '*Skipping sensitivity labels*' -and $Message -like "*$Cloud*"
        }
    }

    It 'preserves an empty section when Graph returns an empty label collection' {
        Mock Invoke-DocGraph { [pscustomobject]@{ value = @() } }

        $result = Get-MIPLabel

        $result.Title | Should -Be 'Labels'
        $result.Objects | Should -BeNullOrEmpty
    }

    It 'returns no section when Graph returns no data' {
        Mock Invoke-DocGraph { $null }

        Get-MIPLabel | Should -BeNullOrEmpty
    }

    It 'preserves unexpected Graph errors' {
        Mock Invoke-DocGraph { throw 'Unexpected Graph failure' }

        { Get-MIPLabel } | Should -Throw '*Unexpected Graph failure*'
    }

    It 'does not request labels when token validation fails' {
        Mock Test-TokenExpiration { throw 'There is no token to refresh.' }

        { Get-MIPLabel } | Should -Throw '*There is no token to refresh.*'
        Should -Invoke Invoke-DocGraph -Times 0 -Exactly
    }
}
