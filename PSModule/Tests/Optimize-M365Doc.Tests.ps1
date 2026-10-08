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
    . "$modulePath\Internal\Translation\Convert-CamelCaseToDisplayName.ps1"
    . "$modulePath\Internal\Translation\Format-MsGraphData.ps1"
    . "$modulePath\Internal\Translation\Optimize-M365DocSection.ps1"
    . "$modulePath\Functions\Optimize-M365Doc.ps1"
}

Describe 'Documentation optimization with absent nested sections' {
    BeforeEach {
        $leaf = [DocSection]::new()
        $leaf.Title = 'Leaf'
        $leaf.Objects = @([pscustomobject]@{ displayName = 'Original value'; id = 'excluded-id' })
        $child = [DocSection]::new()
        $child.Title = 'Child'
        $child.Text = 'Section description'
        $child.Transpose = $true
        $child.SubSections = @($null, $leaf, $null)
        $root = [DocSection]::new()
        $root.Title = 'Root'
        $root.SubSections = @($null, $child, $null)
        $documentation = [Doc]::new()
        $documentation.Organization = 'Test tenant'
        $documentation.Components = @('Intune')
        $documentation.SubSections = @($root)
    }

    It 'skips null entries at every depth and preserves valid sections and optimization options' {
        $result = $documentation | Optimize-M365Doc -UseTranslationFiles -UseCamelCase -ExcludeProperties id -MaxStringLengthSettings 8 -ErrorAction Stop
        $result.Organization | Should -Be 'Test tenant'
        $result.Translated | Should -BeTrue
        $result.SubSections.Count | Should -Be 1
        $optimizedRoot = $result.SubSections[0]
        $optimizedRoot.SubSections.Count | Should -Be 1
        $optimizedChild = $optimizedRoot.SubSections[0]
        $optimizedChild.Title | Should -Be 'Child'
        $optimizedChild.Text | Should -Be 'Section description'
        $optimizedChild.Transpose | Should -BeTrue
        $optimizedChild.SubSections.Count | Should -Be 1
        $optimizedLeaf = $optimizedChild.SubSections[0]
        $optimizedLeaf.Title | Should -Be 'Leaf'
        $optimizedLeaf.Objects[0].'Display Name' | Should -Be 'Original...'
        $optimizedLeaf.Objects[0].PSObject.Properties.Name | Should -Not -Contain 'id'
        $root.SubSections.Count | Should -Be 3
        $leaf.Objects[0].displayName | Should -Be 'Original value'
    }

    It 'returns an empty subsection array when all nested entries are absent' {
        $root.SubSections = @($null, $null)
        $result = $documentation | Optimize-M365Doc -ErrorAction Stop
        $result.SubSections[0].SubSections.Count | Should -Be 0
    }

    It 'still rejects null as the required section argument' {
        { Optimize-M365DocSection -Section $null -ErrorAction Stop } | Should -Throw '*because it is null*'
    }
}
