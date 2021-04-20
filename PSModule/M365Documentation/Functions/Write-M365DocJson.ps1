Function Write-M365DocJson(){
    <#
    .SYNOPSIS
    Outputs the documentation as Json.
    .DESCRIPTION
    This function takes the passed data and is outputing it to the Json file. The Json file can be used to compare old documentations or to recreate documentation by using:
    
    $doc = Get-M365Doc -BackupFile c:\temp\backup.json

    .PARAMETER FullDocumentationPath
    Path including filename where the documentation should be created. The filename has to end with .json.

    .PARAMETER Data
    M365 documentation object which shoult be written to Json.

    .EXAMPLE
    Write-M365DocJson -FullDocumentationPath $FullDocumentationPath -Data $Data

    .NOTES
    NAME: Thomas Kurth / 4.4.2021
    #>
    param(
        [ValidateScript({
            if($_ -notmatch "(\.json)"){
                throw "The file specified in the path argument must be of type json."
            }
            return $true 
        })]
        [System.IO.FileInfo]$FullDocumentationPath,
        [Parameter(ValueFromPipeline,Mandatory)]
        [Doc]$Data
    )
    Begin {

    }
    Process {
        Write-Progress -Id 10 -Activity "Create Json File" -Status "Create File" -PercentComplete 0
        $Data | ConvertTo-Json -Depth 20 | Out-File -FilePath $FullDocumentationPath
        Write-Progress -Id 10 -Activity "Create Json File" -Status "Finished creation" -Completed
    }
    End {
        
    }
}