Function Write-DocumentationMDSection(){
    <#
    .SYNOPSIS
    Outputs a section of the documentation to Markdown
    .DESCRIPTION
    This function takes the passed data and is outputing it to the Markdown file.
    .EXAMPLE
    Write-DocumentationWordSection -FullDocumentationPath $FullDocumentationPath -Data $Data -Level 1

    .NOTES
    NAME: Thomas Kurth / 21.7.2023
    #>
    param(
        [string]$FullDocumentationPath,
        [DocSection]$Data,
        [int]$Level = 1
    )
    
    if($Data.Objects -or $Data.SubSections){
        if(-not [String]::IsNullOrEmpty($Data.Title)){
            $Heading = ""
            $tocspace = ""
            $x = 0
            while($x -le $Level){
                $Heading += "#"
                $tocspace += "  "
                $x = $x + 1
            }
            $Heading += " $($Data.Title)"
            $Heading | Out-File -LiteralPath $FullDocumentationPath -Append
            "" | Out-File -LiteralPath $FullDocumentationPath -Append

            #Fix indentation
            $tocspace = $tocspace.Substring(4)
            $TitleClean = $Data.Title.ToLower().Replace(" ","-") -replace '[^a-zA-Z0-9/_/-]', ''
            $script:toc += "$tocspace- [$($Data.Title)](#$($TitleClean))" + [System.Environment]::NewLine
        }
        if($Data.Text){
            $Data.Text | Out-File -LiteralPath $FullDocumentationPath -Append
            "" | Out-File -LiteralPath $FullDocumentationPath -Append
        }
        if($Data.Objects){   
            if($Data.Transpose){
                foreach($singleObj in $Data.Objects){
                    if($singleObj.displayName -ne $Data.Title -and $Data.Title -ne $singleObj.'Display Name' -and -not [String]::IsNullOrEmpty($singleObj.displayName)){
                        $Heading = ""
                        $x = 0
                        while($x -le ($Level + 1)){
                            $Heading += "#"
                            $x = $x + 1
                        }
                        $Heading += " $($singleObj.displayName)"
                        $Heading | Out-File -LiteralPath $FullDocumentationPath -Append
                        "" | Out-File -LiteralPath $FullDocumentationPath -Append
                    }
                    $singleObj | Format-MarkdownTableListStyle -HideStandardOutput -DoNotCopyToClipboard -ShowMarkdown | Out-File -LiteralPath $FullDocumentationPath -Append
                }
                
            } else {
                $Data.Objects | Format-MarkdownTableTableStyle -HideStandardOutput -DoNotCopyToClipboard -ShowMarkdown | Out-File -LiteralPath $FullDocumentationPath -Append 
            }
            
        }
        foreach($Section in $Data.SubSections){
            Write-DocumentationMDSection -FullDocumentationPath $FullDocumentationPath -Data $Section -Level ($Level + 1)
        }
    }
}