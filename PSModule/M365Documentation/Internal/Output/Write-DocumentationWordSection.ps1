Function Write-DocumentationWordSection(){
    <#
    .SYNOPSIS
    Outputs a section of the documentation to Word
    .DESCRIPTION
    This function takes the passed data and is outputing it to the Word file.
    .EXAMPLE
    Write-DocumentationWordSection -WordDocument $WordDocument -Data $Data -Level 1

    .NOTES
    NAME: Thomas Kurth / 3.3.2021
    #>
    param(
        [object]$WordDocument,
        [DocSection]$Data,
        [int]$Level = 1
    )
    
    if($Data.Objects -or $Data.SubSections){
        Add-WordText -WordDocument $WordDocument -HeadingType "Heading$Level" -Text $Data.Title -Supress $True
        if($Data.Text){
            Add-WordText -WordDocument $WordDocument -Text $Data.Text -Supress $True
        }
        if($Data.Objects){
            
            if($Data.Transpose){
                foreach($singleObj in $Data.Objects){
                    if($singleObj.displayName -ne $Data.Title -and $Data.Title -ne $singleObj.'Display Name'){
                        Add-WordText -WordDocument $WordDocument -HeadingType "Heading$($Level + 1)" -Text $singleObj.displayName -Supress $True
                    }
                    Add-WordTable -WordDocument $WordDocument -DataTable $singleObj -Design LightListAccent2 -Supress $True -Transpose -AutoFit Window
                }
                
            } else {
                Add-WordTable -WordDocument $WordDocument -DataTable $Data.Objects -Design LightListAccent2 -Supress $True -AutoFit Window
            }
            
        }
        foreach($Section in $Data.SubSections){
            Write-DocumentationWordSection -WordDocument $WordDocument -Data $Section -Level ($Level + 1)
        }
    }
}