function Get-M365DocOrderedSections(
    [object[]]$Sections,
    [string]$PriorityTitlePattern = "Management Summary"
) {
    if ($null -eq $Sections) {
        return @()
    }

    $prioritySections = @()
    $remainingSections = @()

    foreach ($section in $Sections) {
        if ($null -ne $section.Title -and $section.Title -match $PriorityTitlePattern) {
            $prioritySections += $section
        }
        else {
            $remainingSections += $section
        }
    }

    return @($prioritySections + $remainingSections)
}
