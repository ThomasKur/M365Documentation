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
        [OfficeIMO.Word.WordDocument]$WordDocument,
        [DocSection]$Data,
        [int]$Level = 1
    )
    
    if($Data.Objects -or $Data.SubSections){
        New-OfficeWordText -Document $WordDocument -Style "Heading$Level" -Text $Data.Title
        if($Data.Text){
            New-OfficeWordText -Document $WordDocument -Text $Data.Text
        }
        if($Data.Objects -and $Data.Objects.Count -gt 0){
            
            if($Data.Transpose){
                foreach($singleObj in $Data.Objects){
                    if($singleObj.displayName -ne $Data.Title -and $Data.Title -ne $singleObj.'Display Name'){
                        New-OfficeWordText -Document $WordDocument -Style "Heading$($Level + 1)" -Text $singleObj.displayName
                    }
                    $table = New-OfficeWordTable -Document $WordDocument -DataTable ($singleObj | Invoke-TransposeObject) -Style GridTable4Accent3
                    $table.Width = 5000
                    $table.WidthType = "Pct"
                }
                
            } else {
                $table = New-OfficeWordTable -Document $WordDocument -DataTable $Data.Objects -Style GridTable4Accent3 
                $table.Width = 5000
                $table.WidthType = "Pct"
            }
            
        }
        foreach($Section in $Data.SubSections){
            Write-DocumentationWordSection -WordDocument $WordDocument -Data $Section -Level ($Level + 1)
        }
    }
}