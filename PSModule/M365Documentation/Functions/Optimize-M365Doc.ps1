Function Optimize-M365Doc(){
    <#
    .DESCRIPTION
    This Script translates as many properties from the Graph API to names used in the UI.

    .PARAMETER Data
    M365 documentation object which should be optimized.

    .PARAMETER UseTranslationFiles
    If available the function will translate property names with the name in the UI. 

    .PARAMETER UseCamelCase
    If no tranlsation is available for a property or the -UseTranslationFiles switch was not used, then property names are beautified based on Caml case standard. 

    .PARAMETER MaxStringLengthSettings
    Values with texts longer than the amount of characters specified by this property then they are trimmed.

    .PARAMETER ExcludeEmptyValues
    Properties with empty values are removed from the output.

    .PARAMETER ExcludeProperties
    Properties with these names are skipped and remove from the output. This can be helpful to remove for example the id or created by property.


    .EXAMPLE 
    $docNew = Optimize-M365Doc -Data $Doc

    .NOTES
    Author: Thomas Kurth/baseVISION
    Date:   05.04.2021

    #>
    [OutputType('Doc')]
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline,Mandatory)]
        [ValidateScript({
            if($_.Translated -eq $true){
                throw "You passed an already optimized/translated M365 document file. This is not supported."
            }
            return $true
        })]
        [Doc]$Data,
        [switch]$UseTranslationFiles,
        [switch]$UseCamelCase,
        [int]$MaxStringLengthSettings = 350,
        [switch]$ExcludeEmptyValues,
        [String[]]$ExcludeProperties
    )
    Begin {

    }
    Process {


        ## Manual Variable Definition
        ########################################################
        #$DebugPreference = "Continue"
        $ScriptName = "Optimize-M365Doc"

        $Script:NewTranslationFiles = @()


        #region Initialization
        ########################################################

        $DataNew = New-Object Doc
        $DataNew.Organization = $Data.Organization
        $DataNew.Components = $Data.Components
        $DataNew.SubSections = @()
        $DataNew.CreationDate = $Data.CreationDate
        $DataNew.Translated = $true

        #endregion

        #region Collection Script
        ########################################################

    
        $progress = 0
        foreach($Section in $Data.SubSections){
            $progress++
            Write-Progress -Id 5 -Activity "Translating documentation" -Status "Translate section" -CurrentOperation $Section.Title -PercentComplete (($progress / $Data.SubSections.count) * 100)
            $DataNew.SubSections += Optimize-M365DocSection -Section $Section -UseTranslationFiles:$UseTranslationFiles -UseCamelCase:$UseCamelCase -MaxStringLengthSettings $MaxStringLengthSettings -ExcludeEmptyValues:$ExcludeEmptyValues -ExcludeProperties $ExcludeProperties
        }

        Write-Progress -Id 5 -Activity "Translating documentation" -Status "Finished translation" -Completed

        #endregion

        #region Finishing
        ########################################################
        
        if($Script:NewTranslationFiles.Count -gt 0 -and $UseTranslationFiles){
            Write-Information "You used the option to translate API properties. Some of the configurations of your tenant could not be translated because translations are missing."
            foreach($file in ($Script:NewTranslationFiles | Select-Object -Unique)){
                Write-Information " - $($file.Replace('Internal\..\',''))"
            }
            Write-Information "You can support the project by translating and submitting the files as issue on the project page. Then it will be included for the future."
            Write-Information "Follow the guide here https://github.com/ThomasKur/IntuneDocumentation/blob/master/AddTranslation.md" 
        }
        
        Write-Information "End Script $Scriptname"

        return $DataNew

        #endregion
    }
    End {
        
    }
}


    