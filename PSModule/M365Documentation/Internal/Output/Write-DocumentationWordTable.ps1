function Write-DocumentationWordTable {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $WordDocument,
        [Parameter(Mandatory)]
        [object[]]$Objects
    )

    # OfficeIMO reflects CLR properties, so unwrap PowerShell objects into dictionaries.
    $rows = [System.Collections.Generic.List[object]]::new()
    foreach ($item in $Objects) {
        $row = [ordered]@{}
        foreach ($property in $item.PSObject.Properties) {
            $row[$property.Name] = [string]$property.Value
        }
        $rows.Add($row)
    }

    $table = $WordDocument.AddTableFromObjects($rows, 'GridTable4Accent3', $true, $null)
    $table.SetWidthPercentage(100)
}
