function Get-ValidSectionValue {
    [CmdletBinding()]
    param()
    $AllCommands = Get-ChildItem -Path "$PSScriptRoot\..\Internal\Collector" -File -Recurse -Depth 1
    return $AllCommands.Name.Replace(".ps1","").Replace("Get-","")
}

function Get-ValidComponentsValue {
    [CmdletBinding()]
    param()
    $AllCommands = Get-ChildItem -Path "$PSScriptRoot\..\Internal\Collector" -Directory 
    return $AllCommands.Name
}

Function Get-M365Doc(){
    <#
    .DESCRIPTION
    This Script documents an settings of your Microsoft 365 environment with almost all settings, which are available over the Graph API.

    The Script is using the MSAL.PS Module and requires you to run Connect-Documentation. Therefore you have to install them first.

    .PARAMETER Components
        Path including filename where the documentation should be created. The filename has to end with .docx.
        Note:
        If there is already a file present, the documentation will be added at the end of the existing document.

    .PARAMETER ExcludeSections
        The specified sections are excluded from the collection process. The following sections are available:

        AzureAD AADAdministrativeUnit
        AzureAD AADAuthMethod
        AzureAD AADBranding
        AzureAD AADConditionalAccess
        AzureAD AADConditionalAccessSplit
        AzureAD AADDirectoryRole
        AzureAD AADDomain
        AzureAD AADIdentityProvider
        AzureAD AADOrganization
        AzureAD AADPolicy
        AzureAD AADSubscription

        CloudPrint CPConnector
        CloudPrint 
        
        InformationProtection MIPLabel

        Intune MdmAdmxConfigurationProfile
        Intune MdmAppleConfiguration
        Intune MdmAutopilotProfile
        Intune MdmCompliancePolicy
        Intune MdmConfigurationPolicy
        Intune MdmConfigurationProfile
        Intune MdmDeviceCategory
        Intune MdmEnrollmentConfiguration
        Intune MdmExchangeConnector
        Intune MdmPartner
        Intune MdmPowerShellScript
        Intune MdmSecurityBaseline
        Intune MdmTermsAndCondition
        Intune MdmWindowsUpdate
        Intune MobileApp
        Intune MobileAppConfiguration
        Intune MobileAppDetailed
        Intune MobileAppManagement

        Windows365 W365Image
        Windows365 W365OnPremConnection
        Windows365 W365ProvisionProfile
        Windows365 W365UserSetting

    .PARAMETER IncludeSections
        Only the specified sections are collected. Keep in mind that you have also to specify the corresponding Component. For example if 
        you choose to include AADConditionalAccess section, but specify Intune as a Component, then nothing will be collected.  

        AzureAD AADAdministrativeUnit
        AzureAD AADAuthMethod
        AzureAD AADBranding
        AzureAD AADConditionalAccess
        AzureAD AADConditionalAccessSplit
        AzureAD AADDirectoryRole
        AzureAD AADDomain
        AzureAD AADIdentityProvider
        AzureAD AADOrganization
        AzureAD AADPolicy
        AzureAD AADSubscription

        CloudPrint CPConnector
        CloudPrint 
        
        InformationProtection MIPLabel

        Intune MdmAdmxConfigurationProfile
        Intune MdmAppleConfiguration
        Intune MdmAutopilotProfile
        Intune MdmCompliancePolicy
        Intune MdmConfigurationPolicy
        Intune MdmConfigurationProfile
        Intune MdmDeviceCategory
        Intune MdmEnrollmentConfiguration
        Intune MdmExchangeConnector
        Intune MdmPartner
        Intune MdmPowerShellScript
        Intune MdmSecurityBaseline
        Intune MdmTermsAndCondition
        Intune MdmWindowsUpdate
        Intune MobileApp
        Intune MobileAppConfiguration
        Intune MobileAppDetailed
        Intune MobileAppManagement

        Windows365 W365Image
        Windows365 W365OnPremConnection
        Windows365 W365ProvisionProfile
        Windows365 W365UserSetting

    .PARAMETER BackupFile
        Path to a previously generated JSON file.
     

    .EXAMPLE Online
    $doc = Get-M365Doc -Components Intune -ExcludeSections "MobileAppDetailed"

    .EXAMPLE Backup
    Retrieves data from backup file. created with Output-M365Doc
    
    $doc = Get-M365Doc -BackupFile c:\temp\backup.json

    .NOTES
    Author: Thomas Kurth/baseVISION
    Date:   01.04.2021

    History
        See Release Notes in Github.

    #>
    [OutputType('Doc')]
    [CmdletBinding(DefaultParameterSetName="Online-Exclude")]
    Param(
 
        [Parameter(ParameterSetName="Online-Exclude",Mandatory=$true)]
        [Parameter(ParameterSetName="Online-Include",Mandatory=$true)]
        [ArgumentCompleter(
            {
                
                param(
                    $Command, 
                    $Parameter, 
                    $WordToComplete, 
                    $CommandAst, 
                    $FakeBoundParams)

                Get-ValidComponentsValue 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-ValidComponentsValue)
            }
        )]
        [string[]]$Components,

        [Parameter(ParameterSetName="Online-Exclude",Mandatory=$false)]
        [ArgumentCompleter(
            {
                
                param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)

                Get-ValidSectionValue 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-ValidSectionValue)
            }
        )]
        [string[]]$ExcludeSections,

        [Parameter(ParameterSetName="Online-Include",Mandatory=$true)]
        [ArgumentCompleter(
            {
                
                param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)

                Get-ValidSectionValue 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-ValidSectionValue)
            }
        )]
        [string[]]$IncludeSections,

        [Parameter(ParameterSetName="Backup",Mandatory=$true)]
        [ValidateScript({
            if($_ -notmatch "(\.json)"){
                throw "The file specified in the path argument must be a valid M365 documentation backup of type json."
            }
            return $true 
        })]
        [System.IO.FileInfo]$BackupFile

    )
    ## Manual Variable Definition
    ########################################################
    #$DebugPreference = "Continue"
    $ScriptName = "Get-M365Doc"

    if( $PsCmdlet.ParameterSetName -eq "Backup"){
        [Doc]$Doc = Get-Content -Path $BackupFile | ConvertFrom-Json
        return $Doc
    } else {

        #region Initialization
        ########################################################
        Write-Log "Start Script $Scriptname"
        # Authentication
        # verify token
        if (-not ($script:token -and $script:token.ExpiresOn.LocalDateTime -ge $(Get-Date))) {
            throw "Please connect first via Connect-M365Doc"
        }

        $Data = New-Object Doc
        $org = Invoke-DocGraph -Path "/organization"
        $Data.Organization = $org.Value.displayName
        $Data.Components = $Components
        $Data.SubSections = @()
        $Data.CreationDate = Get-Date
        $Data.Translated = $false

        #endregion

        #region Collection Script
        ########################################################

        foreach($Component in $Components){
            # Get all collector commands
            $AllCommands = Get-ChildItem -Path "$PSScriptRoot\..\Internal\Collector\$Component" -File 
            
            #Exclude excluded commands
            if( $PsCmdlet.ParameterSetName -eq "Online-Exclude"){
                $SelectedCommands = @()
                foreach($AllCommand in $AllCommands){
                    $Excluded = $false
                    foreach($ExcludeSection in $ExcludeSections){
                        if($AllCommand -match $ExcludeSection){
                            $Excluded = $true
                            Write-Verbose  "Section $AllCommand will be excluded."
                        }
                    }
                    
                    if($Excluded -eq $false){
                        $SelectedCommands += $AllCommand
                    }
                }
            }

            #Include only Included commands from the current component
            if($PsCmdlet.ParameterSetName -eq "Online-Include"){
                $SelectedCommands = @()
                foreach($AllCommand in $AllCommands){
                    $Included = $false
                    foreach($IncludeSection in $IncludeSections){
                        if($AllCommand -match $IncludeSection){
                            $Included = $true
                            Write-Verbose  "Section $AllCommand will be included."
                        }
                    }
                    
                    if($Included){
                        $SelectedCommands += $AllCommand
                    }
                }
            }

            # Start data collection
            $progress = 0
            $CollectedData = @()
            foreach($SelectedCommand in $SelectedCommands){
                $progress++
                Write-Progress -Id 1 -Activity "Collecting Data" -Status (($SelectedCommand.Name -replace ".ps1","") -replace "Get-","") -PercentComplete (($progress / $SelectedCommands.count) * 100)
                $CollectedData += Invoke-Expression -Command ($SelectedCommand.Name -replace ".ps1","")
            }
            Write-Progress -Id 1 -Activity "Collecting Data" -Status "Finished collection" -Completed
            
            # Build return object, depending if multiple components are documented in subsections.
            if($Components.count -gt 1){
                $DocSec = New-Object DocSection
                $DocSec.Title = $Component
                $DocSec.Text = ""
                $DocSec.SubSections = $CollectedData
                $Data.SubSections += $DocSec
            } else {
                $Data.SubSections = $CollectedData
            }

        }

        #endregion

        #region Finishing
        ########################################################
        
        return $Data
        
        Write-Information "End Script $Scriptname"
        #endregion
    }
}
