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
            if( -Not ($_ | Test-Path -PathType Container) ){
                throw "Folder does not exist."
            }
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

        $progress = 0
        foreach($Section in $Data.SubSections){
            $progress++
            Write-Progress -Id 10 -Activity "Create Csv File" -Status "Write Section" -CurrentOperation $Section.Title -PercentComplete (($progress / $Data.SubSections.count) * 100)
            Write-DocumentationCsvSection -CsvPath $ExportFolder -Data $Section -Path "$($Data.CreationDate.ToString("yyyyMMddHHmm"))-$($Section.Title)"
        }

        Write-Progress -Id 10 -Activity "Create Csv File" -Status "Finished creation" -Completed
    }
    End {
        
    }
}