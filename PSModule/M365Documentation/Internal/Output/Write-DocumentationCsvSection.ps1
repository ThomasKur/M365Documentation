Function Write-DocumentationCsvSection(){
    <#
    .SYNOPSIS
    Outputs a section of the documentation to CSV
    .DESCRIPTION
    This function takes the passed data and is outputing it to the CSV file.
    .EXAMPLE
    Write-DocumentationCsvSection -CsvPath $CsvPath -Data $Section -Path "$(Get-Date -Format "yyyyMMddHHmm")-$($Section.Title)"

    .NOTES
    NAME: Thomas Kurth / 3.3.2021
    #>
    param(
        [string]$CsvPath,
        [DocSection]$Data,
        [string]$Path
    )
    
    if($Data.Objects -or $Data.SubSections){
        
        if($Data.Objects){
            $Path = $Path.Split([IO.Path]::GetInvalidFileNameChars()) -join ''
            $Data.Objects | ConvertTo-Csv -NoTypeInformation -Delimiter ";" | Out-File -LiteralPath "$CsvPath\$Path.csv"
        }
        foreach($Section in $Data.SubSections){
            Write-DocumentationCsvSection -CsvPath $CsvPath -Data $Section -Path "$Path-$($Section.Title)"
        }
    }
}
