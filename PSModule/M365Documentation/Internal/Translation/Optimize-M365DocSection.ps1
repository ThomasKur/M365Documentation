Function Optimize-M365DocSection(){
    <#
    .DESCRIPTION
    This Script translates as many properties from the Graph API to names used in the UI.

    .PARAMETER Data
    M365 documentation section object which should be optimized.

    
    .PARAMETER ExcludeValues
    All values are replaced with an empty string.

    .EXAMPLE 
    $docNew = Optimize-M365DocSection -Section $DocSection

    .NOTES
    Author: Thomas Kurth/baseVISION
    Date:   05.04.2021

    #>
    [OutputType('DocSection')]
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline,Mandatory)]
        [DocSection]$Section,
        [switch]$UseTranslationFiles,
        [switch]$UseCamelCase,
        [int]$MaxStringLengthSettings = 350,
        [switch]$ExcludeEmptyValues,
        [switch]$ExcludeValues,
        [String[]]$ExcludeProperties
    )
    Begin {

    }
    Process {
        ## Manual Variable Definition
        ########################################################
        #$DebugPreference = "Continue"
        $ScriptName = "Optimize-M365DocSection"


        #region Initialization
        ########################################################

        $DataNew = New-Object DocSection
        $DataNew.Title = $Section.Title
        $DataNew.Text = $Section.Text
        $DataNew.SubSections = @()
        $DataNew.Objects = @()
        $DataNew.Transpose = $Section.Transpose

        #endregion

        #region Translate
        ########################################################

        foreach($Section2 in $Section.SubSections){
            $DataNew.SubSections += Optimize-M365DocSection -Section $Section2 -UseTranslationFiles:$UseTranslationFiles -UseCamelCase:$UseCamelCase -MaxStringLengthSettings $MaxStringLengthSettings -ExcludeEmptyValues:$ExcludeEmptyValues -ExcludeValues:$ExcludeValues -ExcludeProperties $ExcludeProperties
        }

        foreach($Object in $Section.Objects){
            
            $ObjectNew = New-Object -Type PSObject


            #Prepare File based translation
            $TypeName = $Object.'@odata.type'
            $TranslationFile = "$PSScriptRoot\..\..\Data\LabelTranslation\$TypeName.json"
            $translateJson = Get-Content $TranslationFile -ErrorAction SilentlyContinue
            if($null -eq $translateJson){
                $translateJson = "{}"
            }
            $translation = $translateJson | ConvertFrom-Json


        
            foreach($p in $Object.psobject.properties) {   
                # Skip excluded properties or empty values if specified.
                if($ExcludeProperties -contains $p.Name){
                    continue
                }
                if([string]::IsNullOrWhiteSpace($p.Value) -and $ExcludeEmptyValues){
                    continue
                }
                

                $Translated = $false
                $Name = $p.Name
                $Value = $p.Value


                #File based translation enabled and odata type available
                if($UseTranslationFiles -and (-not ([String]::IsNullOrWhiteSpace($TypeName)))){
                    if([String]::IsNullOrWhiteSpace($translation."$($p.Name)")){
                        $TranslationValue = switch($p.Name){
                            "displayName" { "Displayname" }
                            "lastModifiedDateTime" { "Modified at" }
                            "@odata.type" { "OData Type" }
                            "supportsScopeTags" { "Support for Scope Tags" }
                            "roleScopeTagIds" {  "Role Scopes Tags" }
                            "deviceManagementApplicabilityRuleOsEdition" {  "Applicability OS Edition" }
                            "deviceManagementApplicabilityRuleOsVersion" {  "Applicability OS Version" }
                            "deviceManagementApplicabilityRuleDeviceMode" {  "Applicability Device Mode" }
                            "createdDateTime" {  "Created at" }
                            "description" {  "Description" }
                            "version" {  "Version" }
                            "id" {'ID'}
                            default { '' }   
                        }
                        if(-not ([String]::IsNullOrWhiteSpace($TranslationValue))){
                            $Name = $TranslationValue
                            $Translated = $true
                        }

                        if([String]::IsNullOrWhiteSpace($TranslationValue)){
                            $ConfigSection = " "
                        } else {
                            $ConfigSection = "Metadata"
                        }
            
                        if($p.TypeNameOfValue -eq "System.Boolean"){
                            $TranslationObject = New-Object PSObject -Property @{
                                Name = $TranslationValue
                                Section = $ConfigSection
                                DataType = $p.TypeNameOfValue
                                ValueTrue = "Block"
                                ValueFalse = "Not Configured"
                            }
                        } else {
                            $TranslationObject = New-Object PSObject -Property @{
                                Name = $TranslationValue
                                Section = $ConfigSection
                                DataType = $p.TypeNameOfValue
                            }
                        }
                        
                        $translation | Add-Member Noteproperty -Name $p.Name -Value $TranslationObject -Force 
                        $translation | ConvertTo-Json | Out-File -FilePath $TranslationFile -Force
                        #Variable set for user information in main function
                        $Script:NewTranslationFiles += $TranslationFile
                    } else { 
                        #Only use translated value if not empty  
                        if(-not ([String]::IsNullOrWhiteSpace($translation."$($p.Name)".Name))){
                            if(([String]::IsNullOrWhiteSpace($translation."$($p.Name)".Section))){
                                $Name = "$($translation."$($p.Name)".Name)"
                            } else {
                                $Name = "$($translation."$($p.Name)".Section)\$($translation."$($p.Name)".Name)"
                                $Name = $Name.Replace("/","\")
                            }
                            $Translated = $true
                        }
                    }
                }

                #Camelcase Translation
                if($Translated -eq $false -and $UseCamelCase){
                    #Only use Camel Case converter if not already translated.
                    $TempName = Convert-CamelCaseToDisplayName -Value $p.Name
                    if(-not ([String]::IsNullOrWhiteSpace($TempName))){
                        $Name = $TempName
                    } 
                }
                
                # Optimize Value
                if($p.TypeNameOfValue -eq "System.Boolean"){
                    if(-not ([String]::IsNullOrWhiteSpace($translation."$($p.Name)".Name))){
                        if($p.Value -eq $true){
                            $Value = $translation."$($p.Name)".ValueTrue
                        } else {
                            $Value = $translation."$($p.Name)".ValueFalse
                        }
                    }
                } else {
                    $TempValue = Format-MsGraphData "$($p.Value)"
                    if($TempValue.Length -gt $MaxStringLengthSettings){
                        $Value = "$($TempValue.substring(0, $MaxStringLengthSettings))..."
                    } else {
                        $Value = "$($TempValue) "
                    }
                }
                if($null -eq $Value){
                    $Value = ""
                } else {
                    if($value.GetType().Name -ne "Boolean" -and $value.GetType().Name -ne "System.Boolean"){
                        $value = $value.Trim()
                    }
                }
                if(($ExcludeValues -and $p.Name -in @("Value","ValueName") -and $DataNew.Title -eq "Settings") -or ($ExcludeValues -and $DataNew.Title -ne "Settings")){
                    $Value = ""
                }
                
                try{
                    $ObjectNew | Add-Member Noteproperty $Name $Value -ErrorAction Stop
                } catch {
                    $ObjectNew | Add-Member Noteproperty "$Name`2" $Value -ErrorAction Stop
                }     
            }

            $DataNew.Objects += $ObjectNew
        }

        #endregion

        #region Finishing
        ########################################################
        
        return $DataNew

        if($Script:NewTranslationFiles.Count -gt 0 -and $Script:UseTranslation){
            Write-Information "You used the option to translate API properties. Some of the configurations of your tenant could not be translated because translations are missing."
            foreach($file in ($Script:NewTranslationFiles | Select-Object -Unique)){
                Write-Information " - $($file.Replace('Internal\..\',''))"
            }
            Write-Information "You can support the project by translating and submitting the files as issue on the project page. Then it will be included for the future."
            Write-Information "Follow the guide here https://github.com/ThomasKur/IntuneDocumentation/blob/master/AddTranslation.md" 
        }
        
        Write-Information "End Script $Scriptname"
        #endregion
    }
    End {

    }
}


    