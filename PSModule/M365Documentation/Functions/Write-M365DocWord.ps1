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
            if($_ -notmatch "(\.docx)"){
                throw "The file specified in the path argument must be of type docx."
            }
            if(-not (Test-Path -Path (Split-Path $_ -Parent) -PathType Container)){
                throw "The path specified does not exist '$(Split-Path $_ -Parent)'."
            }
            return $true 
        })]
        [System.IO.FileInfo]$FullDocumentationPath = ".\$($Data.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc.docx",
        [Parameter(ValueFromPipeline,Mandatory)]
        [Doc]$Data
    )
    Begin {

    }
    Process {
        #region CopyTemplate
        Write-Progress -Id 10 -Activity "Create Word File" -Status "Prepare File template" -PercentComplete 0
        
        if((Test-Path -Path $FullDocumentationPath)){
            Write-Warning "File ($FullDocumentationPath) already exists! Therefore, built-in template will not be used." -WarningAction Continue
            $WordDocument = Get-OfficeWord -FilePath $FullDocumentationPath
        } else {
            Copy-Item "$PSScriptRoot\..\Data\Template.docx" -Destination $FullDocumentationPath
            $WordDocument = Get-OfficeWord -FilePath $FullDocumentationPath.FullName
            $WordDocument.FindAndReplace("SYSTEM",($Data.Components -join ", ")) | Out-Null
            $WordDocument.FindAndReplace("DATE",(Get-Date -Format "HH:mm dd.MM.yyyy")) | Out-Null
            $WordDocument.FindAndReplace("TENANT",$Data.Organization) | Out-Null
        }
        Write-Progress -Id 10 -Activity "Create Word File" -Status "Prepared File template" -PercentComplete 10
        #endregion
    
        
        $progress = 0
        foreach($Section in $Data.SubSections){
            $progress++
            Write-Progress -Id 10 -Activity "Create Word File" -Status "Write Section" -CurrentOperation $Section.Title -PercentComplete (($progress / $Data.SubSections.count) * 100)
            Write-DocumentationWordSection -WordDocument $WordDocument -Data $Section -Level ($Level + 1)
        }

        #Update the TOC
        $WordDocument.TableOfContent.Update()

        Save-OfficeWord -Document $WordDocument -FilePath $FullDocumentationPath.FullName
        Write-Progress -Id 10 -Activity "Create Word File" -Status "Finished creation" -Completed

        Write-Information "Press Ctrl + A and then F9 to Update the table of contents and other dynamic fields in the Word document."
    }
    End {
        
    }
}