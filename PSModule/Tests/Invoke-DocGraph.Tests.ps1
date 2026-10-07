BeforeAll {
    . "$PSScriptRoot\..\M365Documentation\Internal\Helper\Invoke-DocGraph.ps1"

    function Test-TokenExpiration {}

    function Get-TestGraphError {
        param($StatusCode, [string]$Code, [string]$Message = 'Graph request failed')

        $exception = [System.Exception]::new($Message)
        $exception | Add-Member NoteProperty Response ([pscustomobject]@{
            StatusCode = $StatusCode
        })
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            $exception, 'GraphError', [System.Management.Automation.ErrorCategory]::InvalidOperation, $null
        )
        $errorRecord.ErrorDetails = [System.Management.Automation.ErrorDetails]::new(
            (@{ error = @{ code = $Code; message = $Message } } | ConvertTo-Json -Compress)
        )
        return $errorRecord
    }
}

Describe 'Invoke-DocGraph licensing failures' {
    BeforeEach {
        Mock Test-TokenExpiration {}
        Mock Write-Warning {}
        Mock Start-Sleep {}
    }

    It 'warns and returns no error data for licensing failures with status <StatusCode>' -ForEach @(
        @{ StatusCode = 403 }
        @{ StatusCode = [System.Net.HttpStatusCode]::Forbidden }
        @{ StatusCode = 400 }
    ) {
        $script:graphError = Get-TestGraphError -StatusCode $StatusCode -Code 'AadPremiumLicenseRequired'
        Mock Invoke-RestMethod { throw $script:graphError }

        $result = Invoke-DocGraph -Path '/roleManagement/directory/roleEligibilitySchedules' -WarningAction Stop

        $result | Should -BeNullOrEmpty
        Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter {
            $Message -like 'AadPremiumLicenseRequired:*' -and
            $Message -like '*Microsoft Entra ID P2 or Microsoft Entra ID Governance*' -and
            $Message -like "*/roleManagement/directory/roleEligibilitySchedules'*" -and
            $WarningAction -eq 'Continue'
        }
    }

    It 'handles licensing failures on subsequent pages without returning partial data' {
        $script:graphError = Get-TestGraphError -StatusCode 403 -Code 'AadPremiumLicenseRequired'
        Mock Invoke-RestMethod {
            if ($Uri -like '*page=2') {
                throw $script:graphError
            }
            return [pscustomobject]@{
                value = @([pscustomobject]@{ id = 'first-page' })
                '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/policies?page=2'
            }
        }

        Invoke-DocGraph -Path '/policies' | Should -BeNullOrEmpty
        Should -Invoke Invoke-RestMethod -Times 2 -Exactly
        Should -Invoke Write-Warning -Times 1 -Exactly
    }

    It 'continues to a successful request after a licensing failure' {
        $script:graphError = Get-TestGraphError -StatusCode 403 -Code 'AadPremiumLicenseRequired'
        Mock Invoke-RestMethod {
            if ($Uri -like '*roleEligibilitySchedules') {
                throw $script:graphError
            }
            return [pscustomobject]@{ value = @([pscustomobject]@{ id = 'domain'; displayName = 'example.com' }) }
        }

        Invoke-DocGraph -Path '/roleManagement/directory/roleEligibilitySchedules' | Should -BeNullOrEmpty
        $result = Invoke-DocGraph -Path '/domains'

        $result.value[0].displayName | Should -Be 'example.com'
    }

    It 'preserves NotFound handling' {
        $script:graphError = Get-TestGraphError -StatusCode ([System.Net.HttpStatusCode]::NotFound) -Code 'Request_ResourceNotFound'
        Mock Invoke-RestMethod { throw $script:graphError }

        $result = Invoke-DocGraph -Path '/organization/tenant/branding'

        $result.Status | Should -Be 'Not Found'
        Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -like 'NotFound:*' }
    }

    It 'does not swallow unrelated unexpected Graph errors' {
        $script:graphError = Get-TestGraphError -StatusCode 500 -Code 'InternalServerError'
        Mock Invoke-RestMethod { throw $script:graphError }

        { Invoke-DocGraph -Path '/domains' } | Should -Throw '*Graph request failed*'
        Should -Invoke Write-Warning -Times 0 -Exactly
    }

    It 'does not swallow malformed error responses' {
        $script:graphError = Get-TestGraphError -StatusCode 500 -Code 'InternalServerError'
        $script:graphError.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('not JSON')
        Mock Invoke-RestMethod { throw $script:graphError }

        { Invoke-DocGraph -Path '/domains' } | Should -Throw
        Should -Invoke Write-Warning -Times 0 -Exactly
    }

    It 'handles licensing failures after throttling on <RequestPage> requests' -ForEach @(
        @{ RequestPage = 'initial' }
        @{ RequestPage = 'paginated' }
    ) {
        $script:graphError = Get-TestGraphError -StatusCode 403 -Code 'AadPremiumLicenseRequired'
        $script:throttleError = Get-TestGraphError -StatusCode 429 -Code 'TooManyRequests'
        $script:requestCount = 0
        $script:requestPage = $RequestPage
        Mock Invoke-RestMethod {
            if ($script:requestPage -eq 'paginated' -and $Uri -notlike '*page=2') {
                return [pscustomobject]@{
                    value = @([pscustomobject]@{ id = 'first-page' })
                    '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/policies?page=2'
                }
            }
            $script:requestCount++
            if ($script:requestCount -eq 1) {
                throw $script:throttleError
            }
            throw $script:graphError
        }

        Invoke-DocGraph -Path '/policies' | Should -BeNullOrEmpty
        Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -like 'AadPremiumLicenseRequired:*' }
    }
}

Describe 'Get-M365Doc with a license-gated collector' {
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
        . "$modulePath\Functions\Get-M365Doc.ps1"
        . "$modulePath\Internal\Collector\AzureAD\Get-AADDirectoryPimRole.ps1"
        . "$modulePath\Internal\Collector\AzureAD\Get-AADDomain.ps1"
    }

    It 'returns a document and preserves successful sections after a PIM licensing error' {
        $script:token = [pscustomobject]@{ ExpiresOn = [DateTimeOffset]::Now.AddHours(1) }
        $script:graphError = Get-TestGraphError -StatusCode 403 -Code 'AadPremiumLicenseRequired'
        Mock Test-TokenExpiration {}
        Mock Write-Warning {}
        Mock Get-ChildItem {
            @(
                [pscustomobject]@{ Name = 'Get-AADDirectoryPimRole.ps1' }
                [pscustomobject]@{ Name = 'Get-AADDomain.ps1' }
            )
        } -ParameterFilter { $File }
        Mock Invoke-RestMethod {
            switch -Wildcard ($Uri) {
                '*/organization' { return [pscustomobject]@{ value = @([pscustomobject]@{ displayName = 'Test tenant' }) } }
                '*/directoryRoles' { return [pscustomobject]@{ value = @() } }
                '*/roleEligibilitySchedules' { throw $script:graphError }
                '*/domains' { return [pscustomobject]@{ value = @([pscustomobject]@{ id = 'example.com' }) } }
                default { throw "Unexpected test request: $Uri" }
            }
        }

        $doc = Get-M365Doc -Components @('AzureAD')

        $doc | Should -Not -BeNullOrEmpty
        $doc.Organization | Should -Be 'Test tenant'
        $domains = $doc.SubSections | Where-Object Title -eq 'Domains'
        $domains.Objects[0].id | Should -Be 'example.com'
        Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -like 'AadPremiumLicenseRequired:*' }
    }
}
