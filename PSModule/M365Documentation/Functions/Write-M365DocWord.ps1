Function Write-M365DocWord(){
    <#
    .SYNOPSIS
    Outputs the documentation as Word file.
    .DESCRIPTION
    This function takes the passed data and is outputing it to the Word file.

    .PARAMETER FullDocumentationPath
    Path including filename where the documentation should be created. The filename has to end with .docx.

    Note:
    If there is already a file present, the documentation will be added at the end of the existing document.

    .PARAMETER Data
    M365 documentation object which shoult be written to DOCX.

    .EXAMPLE
    Write-M365DocWord -FullDocumentationPath $FullDocumentationPath -Data $Data

    .NOTES
    NAME: Thomas Kurth / 3.3.2021
    #>
    param(
        [ValidateScript({
            if($_ -notmatch "(\.docx)$"){
                throw "The file specified in the path argument must be of type docx."
            }

            if(-not (Test-Path -Path (Split-Path $_ -Parent) -PathType Container)){
                throw "The path specified does not exist '$(Split-Path $_ -Parent)'."
            }
            return $true 
        })]
        # MINIMAL CHANGE: avoid referencing $Data here
        [System.IO.FileInfo]$FullDocumentationPath = ".\$(Get-Date -Format 'yyyyMMddHHmm')-WPNinjas-Doc.docx",
        [Parameter(ValueFromPipeline,Mandatory)]
        [Doc]$Data
    )
    Begin {

    }
    Process {
        # MINIMAL ADD: normalize to a full string path and ensure parent folder exists
        $fullPath = [System.IO.Path]::GetFullPath($FullDocumentationPath)
        $parent   = Split-Path -Parent $fullPath
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        #region CopyTemplate
        Write-Progress -Id 10 -Activity "Create Word File" -Status "Prepare File template" -PercentComplete 0
        
        $fileAlreadyExists = Test-Path -LiteralPath $fullPath
        if($fileAlreadyExists){
            Write-Warning "File ($fullPath) already exists! Therefore, built-in template will not be used." -WarningAction Continue
        } else {
            Copy-Item "$PSScriptRoot\..\Data\Template.docx" -Destination $fullPath -ErrorAction Stop
        }
        $WordDocument = Get-OfficeWord -InputPath $fullPath -ErrorAction Stop
        try {
            if (-not $fileAlreadyExists) {
                Update-OfficeWordText -Document $WordDocument -OldValue "SYSTEM" -NewValue ($Data.Components -join ", ") -ErrorAction Stop | Out-Null
                Update-OfficeWordText -Document $WordDocument -OldValue "DATE" -NewValue (Get-Date -Format "HH:mm dd.MM.yyyy") -ErrorAction Stop | Out-Null
                Update-OfficeWordText -Document $WordDocument -OldValue "TENANT" -NewValue $Data.Organization -ErrorAction Stop | Out-Null
            }
            Write-Progress -Id 10 -Activity "Create Word File" -Status "Prepared File template" -PercentComplete 10
            #endregion

            $progress = 0
            $orderedSections = Get-M365DocOrderedSections -Sections $Data.SubSections
            $totalSections = [Math]::Max(1, $orderedSections.Count)

            foreach($Section in $orderedSections){
                $progress++
                Write-Progress -Id 10 -Activity "Create Word File" -Status "Write Section" -CurrentOperation $Section.Title -PercentComplete (($progress / $totalSections) * 100)
                Write-DocumentationWordSection -WordDocument $WordDocument -Data $Section -Level 1
            }

            if ($WordDocument.TableOfContent) {
                $WordDocument.TableOfContent.Update()
            }
            Save-OfficeWord -Document $WordDocument -Path $fullPath -ErrorAction Stop
        }
        finally {
            Close-OfficeWord -Document $WordDocument -ErrorAction Stop
            Write-Progress -Id 10 -Activity "Create Word File" -Status "Finished creation" -Completed
        }

        Write-Information "Press Ctrl + A and then F9 to Update the table of contents and other dynamic fields in the Word document."
    }
    End {
        
    }
}
