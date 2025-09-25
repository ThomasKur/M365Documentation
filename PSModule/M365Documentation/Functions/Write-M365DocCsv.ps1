Function Write-M365DocCsv(){
    <#
    .SYNOPSIS
    Outputs the documentation as CSV.
    .DESCRIPTION
    This function takes the passed data and is outputing it to multiple CSV files.

    .PARAMETER ExportFolder
    Path to the folder where the CSV file based documentation should be created.

    .PARAMETER Data
    M365 documentation object which shoult be written to CSV.

    .EXAMPLE
    Write-M365DocCsv -ExportFolder $ExportFolder -Data $Data

    .NOTES
    NAME: Thomas Kurth / 4.4.2021
    #>
    param(
        [Alias('FullDocumentationPath')]
        [ValidateScript({
            # MINIMAL CHANGE: don't fail if the folder doesn't exist; we'll create it in Process
            if ([string]::IsNullOrWhiteSpace($_)) { throw "ExportFolder cannot be empty." }
            return $true
        })]
        [System.IO.FileInfo]$ExportFolder = ".",
        [Parameter(ValueFromPipeline,Mandatory)]
        [Doc]$Data
    )
    Begin {

    }
    Process {
        Write-Progress -Id 10 -Activity "Create Csv Files" -Status "Create File" -PercentComplete 0

        # MINIMAL ADD: normalize/export folder and ensure it exists
        $csvFolder = [System.IO.Path]::GetFullPath($ExportFolder)
        if (-not (Test-Path -LiteralPath $csvFolder -PathType Container)) {
            New-Item -ItemType Directory -Path $csvFolder -Force | Out-Null
        }

        # Use CreationDate if present; fallback to now (mirrors MD/HTML behavior)
        $stamp = if ($Data -and $Data.CreationDate) { $Data.CreationDate.ToString("yyyyMMddHHmm") } else { (Get-Date -Format "yyyyMMddHHmm") }

        $progress = 0
        foreach($Section in $Data.SubSections){
            $progress++
            Write-Progress -Id 10 -Activity "Create Csv File" -Status "Write Section" -CurrentOperation $Section.Title -PercentComplete (($progress / $Data.SubSections.count) * 100)

            # MINIMAL ADD: make the per-section filename safe
            $safeTitle = ($Section.Title -replace '[\\/:*?"<>|]', '_')

            Write-DocumentationCsvSection -CsvPath $csvFolder -Data $Section -Path "$stamp-$safeTitle"
        }

        Write-Progress -Id 10 -Activity "Create Csv File" -Status "Finished creation" -Completed
    }
    End {
        
    }
}
