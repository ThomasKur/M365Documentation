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
    . "$modulePath\Internal\Collector\Copilot\Get-CopilotPolicySetting.ps1"
    . "$modulePath\Internal\Collector\Copilot\Get-CopilotAdminLimitedMode.ps1"
    . "$modulePath\Internal\Collector\Copilot\Get-CopilotAgentIdentityBlueprint.ps1"

    function Invoke-DocGraph { param($Path, [switch]$Beta) }
}

Describe 'Copilot policy setting collector' {
    BeforeEach {
        $script:M365Doc_CloudEnvironment = 'Commercial'
        Mock Write-Warning {}
        Mock Invoke-DocGraph {
            [pscustomobject]@{ id = ($Path -split '/')[-1]; value = 'enabled'; policyId = 'policy-1' }
        }
    }

    It 'retrieves the documented setting identifiers from the beta API' {
        $result = Get-CopilotPolicySetting -ErrorAction Stop

        $result.Title | Should -Be 'Policy Settings'
        $result.Objects.Count | Should -Be 3
        @($result.Objects.id) | Should -Contain 'microsoft.copilot.copilotchatpinning'
        @($result.Objects.id) | Should -Contain 'microsoft.copilot.imagegeneration'
        @($result.Objects.id) | Should -Contain 'microsoft.copilot.allowwebsearch'
        Should -Invoke Invoke-DocGraph -Times 3 -Exactly -ParameterFilter {
            $Beta -and $Path -like '/copilot/admin/policySettings/*'
        }
    }

    It 'skips policy settings in unsupported national clouds' -ForEach @(
        @{ Cloud = 'USGov' }
        @{ Cloud = 'USGovDoD' }
    ) {
        $script:M365Doc_CloudEnvironment = $Cloud

        Get-CopilotPolicySetting | Should -BeNullOrEmpty

        Should -Invoke Invoke-DocGraph -Times 0 -Exactly
        Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter {
            $Message -like '*policy settings API is not available*' -and $Message -like "*$Cloud*"
        }
    }
}

Describe 'Copilot admin limited mode collector' {
    BeforeEach {
        $script:M365Doc_CloudEnvironment = 'Commercial'
        Mock Write-Warning {}
        Mock Invoke-DocGraph {
            [pscustomobject]@{ isEnabledForGroup = $true; groupId = 'group-1' }
        }
    }

    It 'retrieves the limited mode setting from the v1.0 API' {
        $result = Get-CopilotAdminLimitedMode -ErrorAction Stop

        $result.Title | Should -Be 'Admin Limited Mode'
        $result.Objects.groupId | Should -Be 'group-1'
        Should -Invoke Invoke-DocGraph -Times 1 -Exactly -ParameterFilter {
            $Path -eq '/copilot/admin/settings/limitedMode' -and -not $Beta
        }
    }

    It 'skips limited mode in unsupported national clouds' -ForEach @(
        @{ Cloud = 'USGov' }
        @{ Cloud = 'USGovDoD' }
    ) {
        $script:M365Doc_CloudEnvironment = $Cloud

        Get-CopilotAdminLimitedMode | Should -BeNullOrEmpty

        Should -Invoke Invoke-DocGraph -Times 0 -Exactly
        Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter {
            $Message -like '*API is not available*' -and $Message -like "*$Cloud*"
        }
    }
}

Describe 'Copilot agent identity blueprint collector' {
    BeforeEach {
        Mock Invoke-DocGraph {
            switch -Exact ($Path) {
                '/applications/microsoft.graph.agentIdentityBlueprint' {
                    return [pscustomobject]@{
                        value = @(
                            [pscustomobject]@{ id = 'blueprint-1'; displayName = 'Agent One' }
                            [pscustomobject]@{ id = 'blueprint-2'; displayName = 'Agent Two' }
                        )
                    }
                }
                '/applications/blueprint-1/microsoft.graph.agentIdentityBlueprint/communicationConfiguration' {
                    return [pscustomobject]@{ isOverridableAtAgentIdLevel = $true }
                }
                '/applications/blueprint-2/microsoft.graph.agentIdentityBlueprint/communicationConfiguration' {
                    return [pscustomobject]@{ isOverridableAtAgentIdLevel = $false }
                }
                default { throw "Unexpected Graph path: $Path" }
            }
        }
    }

    It 'includes communication configuration on each blueprint' {
        $result = Get-CopilotAgentIdentityBlueprint -ErrorAction Stop

        $result.Title | Should -Be 'Agent Identity Blueprints'
        $result.Objects.Count | Should -Be 2
        $result.Objects[0].communicationConfiguration.isOverridableAtAgentIdLevel | Should -BeTrue
        $result.Objects[1].communicationConfiguration.isOverridableAtAgentIdLevel | Should -BeFalse
        Should -Invoke Invoke-DocGraph -Times 1 -Exactly -ParameterFilter {
            $Path -eq '/applications/microsoft.graph.agentIdentityBlueprint' -and $Beta
        }
        Should -Invoke Invoke-DocGraph -Times 2 -Exactly -ParameterFilter {
            $Path -like '*/microsoft.graph.agentIdentityBlueprint/communicationConfiguration' -and $Beta
        }
    }

    It 'returns no section when there are no blueprints' {
        Mock Invoke-DocGraph { [pscustomobject]@{ value = @() } }

        Get-CopilotAgentIdentityBlueprint -ErrorAction Stop | Should -BeNullOrEmpty
        Should -Invoke Invoke-DocGraph -Times 1 -Exactly
    }
}
