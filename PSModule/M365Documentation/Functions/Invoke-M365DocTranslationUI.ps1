Function Invoke-M365DocTranslationUI(){
    <#
    .SYNOPSIS
    Translating the ODataTypes to names used in the Microsoft Portal's.
    .DESCRIPTION
    This function opens a UI to simply translate ODataTypes.

    .EXAMPLE
    Invoke-M365DocTranslationUI

    .NOTES
    NAME: Thomas Kurth / 22.5.2021
    #>
    param(
        
    )
    Begin {
        
    }
    Process {
        $TranslationFolder = "$PSScriptRoot\..\Data\LabelTranslation\"
        $o = New-Object M365Doc.UI.Translation -ArgumentList $TranslationFolder

        $o.ShowDialog() | Out-Null
        $o.Focus() | Out-Null
    }
    End {
        
    }
}