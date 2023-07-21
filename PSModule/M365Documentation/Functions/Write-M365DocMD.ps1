Function Write-M365DocMD(){
    <#
    .SYNOPSIS
    Outputs the documentation as Markdown file.
    .DESCRIPTION
    This function takes the passed data and is outputing it to the Markdown file.

    .PARAMETER FullDocumentationPath
    Path including filename where the documentation should be created. The filename has to end with .md.

    Note:
    If there is already a file present, the documentation will be added at the end of the existing document.

    .PARAMETER Data
    M365 documentation object which shoult be written to MD.

    .EXAMPLE
    Write-M365DocMD -FullDocumentationPath $FullDocumentationPath -Data $Data

    .NOTES
    NAME: Thomas Kurth / 21.7.2023
    #>
    param(
        [ValidateScript({
            if($_ -notmatch "(\.md)"){
                throw "The file specified in the path argument must be of type md."
            }
            return $true 
        })]
        [System.IO.FileInfo]$FullDocumentationPath = ".\$($Data.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc.md",
        [Parameter(ValueFromPipeline,Mandatory)]
        [Doc]$Data
    )
    Begin {

    }
    Process {
        #region CopyTemplate
        Write-Progress -Id 10 -Activity "Create Markdown File" -Status "Prepare Markdown template" -PercentComplete 0

        "# M365 Documentation" | Out-File -LiteralPath $FullDocumentationPath -Append
        "" | Out-File -LiteralPath $FullDocumentationPath -Append
        "Date: $(Get-Date -Format "HH:mm dd.MM.yyyy")" | Out-File -LiteralPath $FullDocumentationPath -Append
        "Components: $($Data.Components -join ", ")" | Out-File -LiteralPath $FullDocumentationPath -Append
        "Tenant: $($Data.Organization)" | Out-File -LiteralPath $FullDocumentationPath -Append
        "" | Out-File -LiteralPath $FullDocumentationPath -Append
        "## Contents" | Out-File -LiteralPath $FullDocumentationPath -Append
        "" | Out-File -LiteralPath $FullDocumentationPath -Append
        "_TOC_" | Out-File -LiteralPath $FullDocumentationPath -Append

        Write-Progress -Id 10 -Activity "Create Markdown File" -Status "Prepared Markdown template" -PercentComplete 10
        #endregion
    
        # Prepare TOC
        $script:toc = ""
        
        $progress = 0
        foreach($Section in $Data.SubSections){
            $progress++
            Write-Progress -Id 10 -Activity "Create Markdown File" -Status "Write Section" -CurrentOperation $Section.Title -PercentComplete (($progress / $Data.SubSections.count) * 100)
            Write-DocumentationMDSection -FullDocumentationPath $FullDocumentationPath -Data $Section -Level 1
        }

        # Write TOC
        Write-Progress -Id 10 -Activity "Create Markdown File" -Status "Write TOC" -PercentComplete 99
        $content = Get-Content -LiteralPath $FullDocumentationPath -Raw 
        $content = $content.Replace("_TOC_",$script:toc)
        $content | Out-File -LiteralPath $FullDocumentationPath -Force

        Write-Progress -Id 10 -Activity "Create Markdown File" -Status "Finished creation" -Completed
    }
    End {
        
    }
}