BeforeAll {
    $modulePath = Join-Path (Split-Path -Parent $PSScriptRoot) "M365Documentation"
    Add-Type -TypeDefinition @"
public class DocSection {
    public DocSection[] SubSections { get; set; }
    public string Title { get; set; }
    public string Text { get; set; }
    public object Objects { get; set; }
    public bool Transpose { get; set; }
}
"@
    . "$modulePath/Internal/Collector/Intune/Helper/Get-AssignmentDetailSingle.ps1"
    . "$modulePath/Internal/Collector/Intune/Get-MobileApp.ps1"
    . "$modulePath/Internal/Collector/AzureAD/Get-AADConditionalAccess.ps1"
    . "$modulePath/Internal/Collector/AzureAD/Get-AADPolicy.ps1"
    . "$modulePath/Internal/Collector/CloudPrint/Get-CPPrinter.ps1"
    . "$modulePath/Internal/Helper/Invoke-TransponseObject.ps1"
    . "$modulePath/Internal/Output/Write-DocumentationWordSection.ps1"

    function global:Invoke-DocGraph {
        param($Path, [switch]$Beta)
        $global:GraphCallPaths += $Path
        if($global:GraphResponses.ContainsKey($Path)){
            return $global:GraphResponses[$Path]
        }
        if($Path -like "/deviceManagement/assignmentFilters/*"){
            return [PSCustomObject]@{ displayName = "Test filter" }
        }
        return [PSCustomObject]@{ value = @() }
    }

    function global:Format-MsGraphData { param($Data) return $Data }
    function global:New-OfficeWordText { param($Document, $Style, $Text) }
    function global:New-OfficeWordTable {
        param($Document, $DataTable, $Style)
        $global:WordTables += ,$DataTable
        return [PSCustomObject]@{ Width = 0; WidthType = "" }
    }
    function global:Get-M365DocOrderedSections {
        param($Sections)
        return @($Sections)
    }
}

Describe "Intune assignment targets" {
    BeforeEach {
        $global:GraphResponses = @{}
        $global:GraphCallPaths = @()
        $global:WordTables = @()
    }

    It "retains filter details for All Devices and All Users" {
        $assignments = @(
            [PSCustomObject]@{
                target = [PSCustomObject]@{
                    '@odata.type' = '#microsoft.graph.allDevicesAssignmentTarget'
                    deviceAndAppManagementAssignmentFilterId = 'filter-1'
                    deviceAndAppManagementAssignmentFilterType = 'include'
                }
                intent = 'required'
            },
            [PSCustomObject]@{
                target = [PSCustomObject]@{
                    '@odata.type' = '#microsoft.graph.allLicensedUsersAssignmentTarget'
                    deviceAndAppManagementAssignmentFilterId = 'filter-2'
                    deviceAndAppManagementAssignmentFilterType = 'exclude'
                }
                intent = 'available'
            }
        )

        $results = @($assignments | ForEach-Object { Get-AssignmentDetailSingle -Assignment $_ })

        $results[0].Name | Should -Be "All Devices"
        $results[0].FilterName | Should -Be "Test filter"
        $results[1].Name | Should -Be "All Users"
        $results[1].FilterType | Should -Be "exclude"
    }

    It "documents filters on mobile app assignments to built-in targets" {
        $app = [PSCustomObject]@{ id = 'app-1'; publisher = 'Publisher'; displayName = 'App'; '@odata.type' = '#microsoft.graph.win32LobApp' }
        $assignments = @(
            [PSCustomObject]@{
                target = [PSCustomObject]@{
                    '@odata.type' = '#microsoft.graph.allDevicesAssignmentTarget'
                    deviceAndAppManagementAssignmentFilterId = 'filter-1'
                    deviceAndAppManagementAssignmentFilterType = 'include'
                }
                intent = 'required'
            }
        )
        $global:GraphResponses['/deviceAppManagement/mobileApps'] = [PSCustomObject]@{ value = @($app) }
        $global:GraphResponses['/deviceAppManagement/mobileApps/app-1/assignments'] = [PSCustomObject]@{ value = $assignments }

        $result = Get-MobileApp

        $result.Objects[0].Assignments | Should -Match "All Devices"
        $result.Objects[0].Assignments | Should -Match "Test filter"
    }
}

Describe "Conditional Access and Word output" {
    BeforeEach {
        $global:GraphResponses = @{}
        $global:GraphCallPaths = @()
        $global:WordTables = @()
    }

    It "includes CAE session control values in Conditional Access policies" {
        $policy = [PSCustomObject]@{
            id = 'policy-1'
            displayName = 'CAE policy'
            conditions = [PSCustomObject]@{
                applications = [PSCustomObject]@{}
                users = [PSCustomObject]@{}
            }
            grantControls = [PSCustomObject]@{}
            sessionControls = [PSCustomObject]@{
                continuousAccessEvaluation = 'strictLocation'
                disableResilienceDefaults = $true
            }
        }
        $global:GraphResponses['/identity/conditionalAccess/policies'] = [PSCustomObject]@{ value = @($policy) }

        $result = Get-AADConditionalAccess

        $result.Objects[0].S_ContinuousAccessEvaluation | Should -Be 'strictLocation'
        $result.Objects[0].S_DisableResilienceDefaults | Should -Be $true
    }

    It "does not request the retired standalone CAE policy endpoint" {
        Get-AADPolicy | Out-Null

        $global:GraphCallPaths | Should -Not -Contain '/identity/continuousAccessEvaluationPolicy'
    }

    It "passes section objects through to the Word table writer" {
        $section = [DocSection]@{
            Title = "Policy"
            Objects = [PSCustomObject]@{ setting = 'enabled' }
            Transpose = $false
        }

        Write-DocumentationWordSection -WordDocument ([PSCustomObject]@{}) -Data $section

        $global:WordTables.Count | Should -Be 1
        $global:WordTables[0].setting | Should -Be 'enabled'
    }

    It "preserves false and zero-valued settings in transposed Word data" {
        $section = [DocSection]@{
            Title = "Policy"
            Objects = @([PSCustomObject]@{ M_DisplayName = "Feature"; Enabled = $false; RetryCount = 0 })
            Transpose = $true
        }

        Write-DocumentationWordSection -WordDocument ([PSCustomObject]@{}) -Data $section

        ($global:WordTables[0] | Where-Object Property -eq 'Enabled').Feature | Should -Be $false
        ($global:WordTables[0] | Where-Object Property -eq 'RetryCount').Feature | Should -Be 0
    }

    It "uses literal Cloud Print subsection titles" {
        $printer = [PSCustomObject]@{ id = 'printer-1'; displayName = 'Printer' }
        $global:GraphResponses['/print/printers'] = [PSCustomObject]@{ value = @($printer) }

        $result = Get-CPPrinter

        $result.SubSections[0].SubSections.Title | Should -Contain 'Shares'
        $result.SubSections[0].SubSections.Title | Should -Contain 'Connectors'
    }
}
