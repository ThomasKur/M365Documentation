BeforeAll {
    $modulePath = "$PSScriptRoot\..\M365Documentation"
    $moduleAst = [System.Management.Automation.Language.Parser]::ParseFile(
        "$modulePath\M365Documentation.psm1", [ref]$null, [ref]$null
    )
    $dependencyStatements = $moduleAst.EndBlock.Statements | Where-Object {
        $_.Extent.Text -match '^\$PSModulePSWriteOffice =|^if\s*\(\$PSModulePSWriteOffice'
    }
    $script:loadWordDependency = [scriptblock]::Create(($dependencyStatements.Extent.Text -join "`n"))
}

Describe 'Word dependency loading for direct module-script imports' {
    BeforeEach {
        Mock Import-Module {}
    }

    It 'imports at least version 1.0.2 when the dependency is not loaded' {
        Mock Get-Module {}
        & $script:loadWordDependency
        Should -Invoke Import-Module -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'PSWriteOffice' -and $MinimumVersion -eq [version]'1.0.2' -and $ErrorAction -eq 'Stop'
        }
    }

    It 'rejects an already-loaded legacy version with restart guidance' {
        Mock Get-Module { [pscustomobject]@{ Version = [version]'0.2.0' } }
        { & $script:loadWordDependency } | Should -Throw '*restart PowerShell*'
        Should -Invoke Import-Module -Times 0 -Exactly
    }

    It 'reuses an already-loaded supported version' {
        Mock Get-Module { [pscustomobject]@{ Version = [version]'1.0.2' } }
        & $script:loadWordDependency
        Should -Invoke Import-Module -Times 0 -Exactly
    }

    It 'does not swallow dependency import errors' {
        Mock Get-Module {}
        Mock Import-Module { throw 'Required dependency is unavailable' }
        { & $script:loadWordDependency } | Should -Throw '*Required dependency is unavailable*'
    }
}

Describe 'Local test entry points' {
    It 'imports the manifest and stops on dependency failures' {
        foreach ($file in @('test.ps1', 'test2.ps1')) {
            $content = Get-Content "$PSScriptRoot\..\$file" -Raw
            $content | Should -Match 'Import-Module .*M365Documentation\.psd1.*-ErrorAction Stop'
            $content | Should -Not -Match 'Import-Module .*M365Documentation\.psm1'
        }
    }
}
