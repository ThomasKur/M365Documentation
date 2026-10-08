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
    . "$modulePath\Internal\Helper\Get-M365DocOrderedSections.ps1"
    . "$modulePath\Internal\Helper\Invoke-TransponseObject.ps1"
    . "$modulePath\Internal\Output\Write-DocumentationWordTable.ps1"
    . "$modulePath\Internal\Output\Write-DocumentationWordSection.ps1"
    . "$modulePath\Functions\Write-M365DocWord.ps1"

    Import-Module PSWriteOffice -MinimumVersion 1.0.2 -ErrorAction Stop

    function Read-WordDocumentXml {
        param([string]$Path)
        $archive = [System.IO.Compression.ZipFile]::OpenRead($Path)
        try {
            $reader = [System.IO.StreamReader]::new($archive.GetEntry('word/document.xml').Open())
            try {
                [xml]$reader.ReadToEnd()
            }
            finally {
                $reader.Dispose()
            }
        }
        finally {
            $archive.Dispose()
        }
    }
}

Describe 'Word export dependency requirements' {
    It 'requires PSWriteOffice 1.0.2 or later in the manifest and both publishing branches' {
        $manifest = Import-PowerShellDataFile "$modulePath\M365Documentation.psd1"
        $dependency = $manifest.RequiredModules | Where-Object { $_.ModuleName -eq 'PSWriteOffice' }
        $dependency.ModuleVersion | Should -Be '1.0.2'
        $buildAst = [System.Management.Automation.Language.Parser]::ParseFile(
            "$PSScriptRoot\..\build.ps1", [ref]$null, [ref]$null
        )
        $updates = $buildAst.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.CommandAst] -and
            $node.GetCommandName() -eq 'Update-ModuleManifest'
        }, $true)
        $updates.Count | Should -Be 2
        foreach ($update in $updates) {
            $update.Extent.Text | Should -Match 'ModuleName = "PSWriteOffice"; ModuleVersion = "1.0.2"'
        }
    }

    It 'does not constrain the document parameter to an external assembly type' {
        (Get-Command Write-DocumentationWordSection).Parameters.WordDocument.ParameterType | Should -Be ([object])
        (Get-Content "$modulePath\Internal\Output\Write-DocumentationWordSection.ps1" -Raw) |
            Should -Not -Match '\[OfficeIMO\.'
    }
}

Describe 'Word export with the loaded supported PSWriteOffice version' {
    BeforeEach {
        $script:path = Join-Path $TestDrive "$([guid]::NewGuid()).docx"
        $normal = [DocSection]::new()
        $normal.Title = 'Devices'
        $normal.Text = 'Device overview'
        $normal.Objects = @(
            [pscustomobject][ordered]@{ Name = 'Device A'; Enabled = $true; Tags = @('First', 'Second'); Missing = $null }
            [pscustomobject][ordered]@{ Name = 'Device B'; Enabled = $false; Tags = @(); Missing = $null }
        )
        $summary = [DocSection]::new()
        $summary.Title = 'Management Summary'
        $summary.Objects = @([pscustomobject]@{ Summary = 'All systems documented' })
        $details = [DocSection]::new()
        $details.Title = 'Policies'
        $details.Transpose = $true
        $details.Objects = @([pscustomobject][ordered]@{ displayName = 'Policy A'; Setting = 'Configured' })
        $empty = [DocSection]::new()
        $empty.Title = 'Empty section'
        $empty.Objects = @()
        $normal.SubSections = @($details, $empty)
        $documentation = [Doc]::new()
        $documentation.Organization = 'Compatibility tenant'
        $documentation.Components = @('Intune', 'Entra ID')
        $documentation.SubSections = @($normal, $summary)
    }

    It 'creates a readable DOCX with template replacements, ordered headings, tables and TOC' {
        $result = Write-M365DocWord -FullDocumentationPath $path -Data $documentation
        $result | Should -BeNullOrEmpty
        $xml = Read-WordDocumentXml $path
        $xml.DocumentElement.InnerText | Should -Match 'Compatibility tenant'
        $xml.DocumentElement.InnerText | Should -Match 'Intune, Entra ID'
        $xml.DocumentElement.InnerText | Should -Not -Match '(?-i:TENANT|SYSTEM|DATE)|Empty section'
        $xml.DocumentElement.InnerText | Should -Match 'Device overview'

        $headings = @($xml.SelectNodes("//*[local-name()='p'][*[local-name()='pPr']/*[local-name()='pStyle'][starts-with(@*[local-name()='val'], 'Heading')]]"))
        $titles = @($headings | ForEach-Object { ($_.SelectNodes(".//*[local-name()='t']") | ForEach-Object InnerText) -join '' })
        $titles | Should -Be @('Management Summary', 'Devices', 'Policies', 'Policy A')
        $styles = @($headings | ForEach-Object { $_.SelectSingleNode("./*[local-name()='pPr']/*[local-name()='pStyle']").GetAttribute('val', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main') })
        $styles | Should -Be @('Heading1', 'Heading1', 'Heading2', 'Heading3')

        $xml.SelectNodes("//*[local-name()='tbl']").Count | Should -Be 4
        $tables = @($xml.SelectNodes("//*[local-name()='tbl'][*[local-name()='tblPr']/*[local-name()='tblStyle'][@*[local-name()='val']='GridTable4-Accent3']]"))
        $tables.Count | Should -Be 3
        foreach ($table in $tables) {
            $properties = $table.SelectSingleNode("./*[local-name()='tblPr']")
            $properties.InnerXml | Should -Match 'GridTable4-Accent3'
            $properties.SelectSingleNode("./*[local-name()='tblW']").GetAttribute('w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main') | Should -Be '5000'
            $properties.SelectSingleNode("./*[local-name()='tblW']").GetAttribute('type', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main') | Should -Be 'pct'
        }
        $tables[1].InnerText | Should -Match 'NameEnabledTagsMissing'
        $tables[1].InnerText | Should -Match 'Device ATrueFirst Second'
        $tables[1].InnerText | Should -Match 'Device BFalse'
        $tables[1].InnerText | Should -Not -Match 'System.Object|ImmediateBaseObject'
        $tables[2].InnerText | Should -Match 'PropertyValue'
        $tables[2].InnerText | Should -Match 'SettingConfigured'
        $xml.InnerXml | Should -Match 'TOC'

        $reopened = Get-OfficeWord -InputPath $path -ErrorAction Stop
        try {
            $reopened.Tables.Count | Should -Be 4
        }
        finally {
            Close-OfficeWord -Document $reopened -ErrorAction Stop
        }
    }

    It 'skips blank section and object headings while preserving their content (<Title>)' -TestCases @(
        @{ Title = $null }
        @{ Title = '' }
        @{ Title = '   ' }
    ) {
        param($Title)

        $normal.Title = $Title
        $details.Objects = @(
            [pscustomobject]@{ Setting = 'Missing name' }
            [pscustomobject]@{ displayName = $null; Setting = 'Null name' }
            [pscustomobject]@{ displayName = ''; Setting = 'Empty name' }
            [pscustomobject]@{ displayName = '   '; Setting = 'Whitespace name' }
            [pscustomobject]@{ 'Display Name' = 'Translated policy'; Setting = 'Translated name' }
            [pscustomobject]@{ displayName = 'Policy A'; Setting = 'Configured' }
        )

        Write-M365DocWord -FullDocumentationPath $path -Data $documentation
        $xml = Read-WordDocumentXml $path
        $headings = @($xml.SelectNodes("//*[local-name()='p'][*[local-name()='pPr']/*[local-name()='pStyle'][starts-with(@*[local-name()='val'], 'Heading')]]"))
        $titles = @($headings | ForEach-Object { ($_.SelectNodes(".//*[local-name()='t']") | ForEach-Object InnerText) -join '' })
        $titles | Should -Be @('Management Summary', 'Policies', 'Translated policy', 'Policy A')
        $styles = @($headings | ForEach-Object { $_.SelectSingleNode("./*[local-name()='pPr']/*[local-name()='pStyle']").GetAttribute('val', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main') })
        $styles | Should -Be @('Heading1', 'Heading2', 'Heading3', 'Heading3')
        $xml.SelectNodes("//*[local-name()='tbl']").Count | Should -Be 9
        foreach ($text in @('Device overview', 'Device A', 'Missing name', 'Null name', 'Empty name', 'Whitespace name', 'Translated policy', 'Configured')) {
            $xml.DocumentElement.InnerText | Should -Match $text
        }
    }

    It 'resolves transposed headings from <PropertyName> and skips blank or duplicate titles' -TestCases @(
        @{ PropertyName = 'displayName' }
        @{ PropertyName = 'Display Name' }
        @{ PropertyName = 'M_DisplayName' }
        @{ PropertyName = 'M_Display Name' }
    ) {
        param($PropertyName)

        $details.Objects = @(
            [pscustomobject]@{ $PropertyName = 'Policy A'; Setting = 'Named object' }
            [pscustomobject]@{ $PropertyName = $null; Setting = 'Null title' }
            [pscustomobject]@{ $PropertyName = ''; Setting = 'Empty title' }
            [pscustomobject]@{ $PropertyName = '   '; Setting = 'Whitespace title' }
            [pscustomobject]@{ $PropertyName = 'Policies'; Setting = 'Duplicate title' }
            [pscustomobject]@{ displayName = '   '; 'Display Name' = ''; M_DisplayName = $null; 'M_Display Name' = 'Fallback policy'; Setting = 'Fallback title' }
            [pscustomobject]@{ displayName = 'Preferred policy'; 'Display Name' = 'Alternate policy'; M_DisplayName = 'Metadata policy'; 'M_Display Name' = 'Translated metadata policy' }
        )

        Write-M365DocWord -FullDocumentationPath $path -Data $documentation
        $xml = Read-WordDocumentXml $path
        $headings = @($xml.SelectNodes("//*[local-name()='p'][*[local-name()='pPr']/*[local-name()='pStyle'][starts-with(@*[local-name()='val'], 'Heading')]]"))
        $titles = @($headings | ForEach-Object { ($_.SelectNodes(".//*[local-name()='t']") | ForEach-Object InnerText) -join '' })
        $titles | Should -Be @('Management Summary', 'Devices', 'Policies', 'Policy A', 'Fallback policy', 'Preferred policy')
        $xml.SelectNodes("//*[local-name()='tbl']").Count | Should -Be 10
        foreach ($text in @('Named object', 'Null title', 'Empty title', 'Duplicate title', 'Fallback title')) {
            $xml.DocumentElement.InnerText | Should -Match $text
        }
    }

    It 'appends to an existing document without replacing its text or requiring a TOC' {
        New-OfficeWord -OutputPath $path { Add-OfficeWordParagraph -Text 'Existing TENANT SYSTEM DATE' } -ErrorAction Stop
        Write-M365DocWord -FullDocumentationPath $path -Data $documentation -WarningAction SilentlyContinue
        $xml = Read-WordDocumentXml $path
        $xml.DocumentElement.InnerText | Should -Match 'Existing TENANT SYSTEM DATE'
        $xml.DocumentElement.InnerText | Should -Match 'Device A'
        Write-M365DocWord -FullDocumentationPath $path -Data $documentation -WarningAction SilentlyContinue
        $xml = Read-WordDocumentXml $path
        $xml.SelectNodes("//*[local-name()='tbl']").Count | Should -Be 6
    }

    It 'writes an empty documentation object without empty tables' {
        $documentation.SubSections = @()
        Write-M365DocWord -FullDocumentationPath $path -Data $documentation
        $xml = Read-WordDocumentXml $path
        $xml.SelectNodes("//*[local-name()='tbl']").Count | Should -Be 1
        $xml.SelectNodes("//*[local-name()='tblStyle'][@*[local-name()='val']='GridTable4-Accent3']").Count | Should -Be 0
        $xml.DocumentElement.InnerText | Should -Match 'Compatibility tenant'
    }

    It 'surfaces rendering failures and releases the document file' {
        Mock Write-DocumentationWordSection { throw 'Simulated rendering failure' }
        { Write-M365DocWord -FullDocumentationPath $path -Data $documentation } |
            Should -Throw '*Simulated rendering failure*'
        $stream = [System.IO.File]::Open($path, 'Open', 'ReadWrite', 'None')
        $stream.Dispose()
        Should -Invoke Write-DocumentationWordSection -Times 1 -Exactly
    }
}
