Function Write-M365DocHTML(){
    <#
    .SYNOPSIS
    Outputs the documentation as HTML file.
    .DESCRIPTION
    This function takes the passed data and is outputing it to a html file.

    .PARAMETER FullDocumentationPath
    Path including filename where the documentation should be created. The filename has to end with .docx.

    Note:
    If there is already a file present, the documentation will be added at the end of the existing document.

    .PARAMETER Data
    M365 documentation object which shoult be written to DOCX.

    .PARAMETER Fragment
    If set to $true, the Output will only consist of the part between <body> and </body>. Useful if you want to put the content into another system like confluence.

    .EXAMPLE
    Write-M365DocHTML -FullDocumentationPath $FullDocumentationPath -Data $Data -Fragment $true

    .NOTES
    NAME: Nico Schmidtbauer / 24.03.2025
    #>
    param(
        [ValidateScript({
            if($_ -notmatch "(\.html)"){
                throw "The file specified in the path argument must be of type html."
            }
            return $true 
        })]
        [System.IO.FileInfo]$FullDocumentationPath = ".\$($Data.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-HTML.html",
        $fragment = $false,
        [Parameter(ValueFromPipeline,Mandatory)]
        $Data
        
    )
    Begin {

    }
    Process {
        #region CopyTemplate
        Write-Progress -Id 10 -Activity "Create HTML File" -Status "Prepare template" -PercentComplete 0

        #$htmlTemplate = Get-Content "$PSScriptRoot\..\Data\TemplateHTMLFragment.html"
        $htmlTemplate = Get-Content "$tempPSScriptRoot\..\Data\TemplateHTMLBody.html" -raw
        
        # Replace Basic Data
        $htmlTemplate = $htmlTemplate -replace "TOBEREPLACED-COMPONENTS",$($Data.Components -join ", ") `
        -replace "TOBEREPLACED-DATE",$(Get-Date -Format "HH:mm dd.MM.yyyy") `
        -replace "TOBEREPLACED-TENANT",$Data.Organization
        
        Write-Progress -Id 10 -Activity "Create HTML File" -Status "Prepared template" -PercentComplete 10

        $progress = 0
        $codeObj = @()
        foreach($Section in $Data.SubSections){
            Write-Progress -Id 10 -Activity "Create HTML File" -Status "Write Section" -CurrentOperation $Section.Title -PercentComplete (($progress / $Data.SubSections.count) * 100)
            $progress++
            $codeObj += Write-DocumentationHTMLSection -Data $Section
        }

        $htmlTemplate = $htmlTemplate -replace "TOBEREPLACED-INDEX",$($codeObj.IndexCode -join " ")
        

        $htmlTemplate += $codeObj.bodycode
        if($fragment -eq $false) {
            $outputFile = Get-Content "$tempPSScriptRoot\..\Data\TemplateHTML.html" -Raw
            $outputFile = $outputFile -replace "TOBEREPLACED-BODY",$htmlTemplate
        }
        else {
            $outputFile = $htmlTemplate

        }

        $outputFile | Out-File -FilePath $FullDocumentationPath

        Write-Progress -Id 10 -Activity "Create HTML File" -Status "Finished creation" -Completed
    }
    End {
        
    }
}