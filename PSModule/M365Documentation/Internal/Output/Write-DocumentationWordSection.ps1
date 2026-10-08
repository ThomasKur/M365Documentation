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
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $WordDocument,
        [DocSection]$Data,
        [int]$Level = 1
    )
    
    if($Data.Objects -or $Data.SubSections){
        if(-not [string]::IsNullOrWhiteSpace($Data.Title)){
            $paragraph = $WordDocument.AddParagraph($Data.Title)
            $paragraph.Style = "Heading$Level"
        }
        if($Data.Text){
            $WordDocument.AddParagraph($Data.Text) | Out-Null
        }
        if($Data.Objects -and $Data.Objects.Count -gt 0){
            
            if($Data.Transpose){
                foreach($singleObj in $Data.Objects){
                    $objectTitle = $null
                    foreach($propertyName in @('displayName', 'Display Name', 'M_DisplayName', 'M_Display Name')){
                        $candidateTitle = [string]$singleObj.$propertyName
                        if(-not [string]::IsNullOrWhiteSpace($candidateTitle)){
                            $objectTitle = $candidateTitle
                            break
                        }
                    }
                    if(-not [string]::IsNullOrWhiteSpace($objectTitle) -and $objectTitle -ne $Data.Title){
                        $paragraph = $WordDocument.AddParagraph($objectTitle)
                        $paragraph.Style = "Heading$($Level + 1)"
                    }
                    Write-DocumentationWordTable -WordDocument $WordDocument -Objects ($singleObj | Invoke-TransposeObject)
                }
                
            } else {
                Write-DocumentationWordTable -WordDocument $WordDocument -Objects $Data.Objects
            }
            
        }
        $orderedSubSections = Get-M365DocOrderedSections -Sections $Data.SubSections
        foreach($Section in $orderedSubSections){
            Write-DocumentationWordSection -WordDocument $WordDocument -Data $Section -Level ($Level + 1)
        }
    }
}