Function Write-M365DocHTML(){
    <#
    .SYNOPSIS
    Outputs the documentation as HTML file.
    .DESCRIPTION
    This function takes the passed data and is writing it to a html file.

    .PARAMETER FullDocumentationPath
    Path including filename where the documentation should be created. The filename has to end with .html.

    Note:
    If there is already a file present, the file will be overwritten.

    .PARAMETER Data
    M365 documentation object which shoult be written to DOCX.

    .PARAMETER Fragment
    If set to $true, the Output will only consist of the part between <body> and </body>. Useful if you want to put the content into another system like confluence.

    .PARAMETER Template
    Option to set a custom HTML Template

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
        [ValidateScript({
            if($_ -notmatch "(\.html)"){
                throw "The template file specified in the path argument must be of type html."
            }
            return $true 
        })]
        [System.IO.FileInfo]$template = "$PSScriptRoot\..\Data\TemplateHTML.html",
        $fragment = $false,
        [Parameter(ValueFromPipeline,Mandatory)]
        $Data
        
    )
    Begin {
        $PSHTML = Get-Module -Name PSHTML
        if($PSHTML){
            #Write-Verbose -Message "PSHTML PowerShell module is loaded."
        } else {
            Write-Warning -Message "PSHTML PowerShell module is not loaded, trying to import it."
            try {
                Import-Module -Name PSHTML -ErrorAction Stop
            }
            catch {
                Write-Warning -Message "This function requires PSHTML PowerShell module, which is currently not installed. Please install the module."
                return
            }
        }
    }
    Process {
        Write-Progress -Id 10 -Activity "Create HTML File" -Status "Prepare template" -PercentComplete 0
        # Read HTML Template
        $htmlTemplate = Get-Content "$PSScriptRoot\..\Data\TemplateHTMLBody.html" -raw
        
        # Replace Basic Data
        $htmlTemplate = $htmlTemplate -replace "TOBEREPLACED-COMPONENTS",$($Data.Components -join ", ") `
        -replace "TOBEREPLACED-DATE",$(Get-Date -Format "HH:mm dd.MM.yyyy") `
        -replace "TOBEREPLACED-TENANT",$Data.Organization
        
        Write-Progress -Id 10 -Activity "Create HTML File" -Status "Prepared template" -PercentComplete 10

        $progress = 0

        # Run through secions and catch returns
        $codeObj = @()
        foreach($Section in $Data.SubSections){
            Write-Progress -Id 10 -Activity "Create HTML File" -Status "Write Section" -CurrentOperation $Section.Title -PercentComplete (($progress / $Data.SubSections.count) * 100)
            $progress++
            $codeObj += Write-DocumentationHTMLSection -Data $Section
        }

        # Replace the index in the HTML Template and add the HTML Body code
        $htmlTemplate = $htmlTemplate -replace "TOBEREPLACED-INDEX",$($codeObj.IndexCode -join " ")
        $htmlTemplate += $codeObj.bodycode
        
        # Merge with top html template if no fragment is wanted
        if($fragment -eq $false) {
            $outputFile = Get-Content $template -Raw
            $outputFile = $outputFile -replace "TOBEREPLACED-BODY",$htmlTemplate
        }
        else {
            $outputFile = $htmlTemplate

        }

        # Output File
        $outputFile | Out-File -FilePath $FullDocumentationPath

        Write-Progress -Id 10 -Activity "Create HTML File" -Status "Finished creation" -Completed
    }
    End {
        
    }
}