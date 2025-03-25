Function Write-DocumentationHTMLSection(){
    <#
    .SYNOPSIS
    Outputs a section of the documentation to HTML
    .DESCRIPTION
    This function takes the passed data and is outputing it to the HTML file.
    .EXAMPLE
    Write-DocumentationHtmlSection -HtmlPath $-HtmlPath -Data $Section -Path "$(Get-Date -Format "yyyyMMddHHmm")-$($Section.Title)" -Template $template

    .NOTES
    NAME: Nico Schmidtbauer / 24.03.2025
    #>
    param(
        $Data,
        $Transpose
    )

    # Define Object to be returned at the end
    $retObj = New-Object -TypeName PSObject
    $retObj | Add-Member -MemberType NoteProperty -Name "IndexCode" -Value ""
    $retObj | Add-Member -MemberType NoteProperty -Name "BodyCode" -Value ""

    # Run through object
    if($Data.Objects -or $Data.SubSections){
        # Clean Title to set Links from the Index to the Content
        $TitleClean = $Data.Title.ToLower().Replace(" ","-") -replace '[^a-zA-Z0-9/_/-]', ''
        if($data.Transpose -eq $true) { $Transpose = $true }

        if($Data.Objects){  
            # Output an H3 Heading for Objects and add link for index
            $retObj.BodyCode += "<h3 id=""$titleClean"">$($Section.Title)</h3><p>$($Section.Text)</p>"
            $retObj.IndexCode += "<li><a href=""#$TitleClean"">$($Section.Title)</a></li>"

            # Transpose Objects if needed
            if($Transpose -eq $true) { 
                #$subindex = "<ul>" # Commented out for now - Index gets too big
                foreach($object in $data.Objects) {
                    # Output a heading for each object
                    if($object.displayName -or $object.M_DisplayName) {
                        if($object.displayName) { $dn = $object.displayName}
                        else {$dn = $object.M_DisplayName }
                        $displayNameClean = $Data.Title.ToLower().Replace(" ","-") -replace '[^a-zA-Z0-9/_/-]', ''
                        $retObj.BodyCode += "<h4 id=""$displayNameClean"">$dn</h4>"
                        #$retObj.IndexCode += "<li><a href=""#$displayNameClean"">$dn</a></li>"  # Commented out for now - Index gets too big
                    }

                    # Handle descriptions. Especially Mobile Apps can have unicode characters in their description making later handling of the files harder.
                    if($object.description) {
                        # HTML Encode things like umlauts, remove non latin characters and add proper linebreaks
                        $object.description = [System.Net.WebUtility]::HtmlEncode($object.description)
                        $object.description = $object.description -creplace '\P{IsBasicLatin}'
                        $object.description = $($object.description).replace([System.Environment]::NewLine, "<br />")
                        $object.description = $($object.description).replace('`r', "<br />")
                    }

                    $retObj.BodyCode += Invoke-TransposeObject -InputObject $object |  ConvertTo-PshtmlTable

                }
                # $subindex += "</ul>"  # Commented out for now - Index gets too big
            }
            else {
                $retObj.BodyCode += $data.Objects |  ConvertTo-PshtmlTable
            }
        }
        else {
            # Output an H2 Heading for SubSections and add link for index
            $retObj.BodyCode += "<h2 id=""$titleClean"">$($Section.Title)</h2><p>$($Section.Text)</p>"
            $retObj.IndexCode += "<li><a href=""#$TitleClean"">$($Section.Title)</a></li>"
        }
        foreach($Section in $Data.SubSections){
            $sectReturn = Write-DocumentationHTMLSection -Data $Section -Transpose $data.Transpose
            $retObj.BodyCode += $sectReturn.BodyCode
            if(-not [string]::IsNullOrEmpty($sectReturn.IndexCode)) {
                $retObj.IndexCode += "<ul>$($sectReturn.IndexCode)</ul>"
            }
        }
    }

    return $retObj

}
