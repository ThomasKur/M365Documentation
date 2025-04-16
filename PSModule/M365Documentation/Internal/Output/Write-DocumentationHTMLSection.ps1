Function Write-DocumentationHTMLSection(){
    <#
    .SYNOPSIS
    Outputs a section of the documentation to HTML

    .DESCRIPTION
    This function takes the passed data and is outputing it to the HTML file.

    .EXAMPLE
    Write-DocumentationHtmlSection -Data $Section -Transpose $true

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
                foreach($object in $data.Objects) {
                    # Output a heading for each object
                    if($object.displayName -or $object.M_DisplayName) {
                        if($object.displayName) { $dn = $object.displayName}
                        else {$dn = $object.M_DisplayName }

                        # If the $dn is same as the section title, we have already output it as H3, no need to output it again then.
                        if($dn -ne $($Section.Title)) {
                            $displayNameClean = $dn.ToLower().Replace(" ","-") -replace '[^a-zA-Z0-9/_/-]', ''
                            $retObj.BodyCode += "<h4 id=""$displayNameClean"">$dn</h4>"
                            $retObj.IndexCode += "<ul><li><a href=""#$displayNameClean"">$dn</a></li></ul>"  # Commented out for now - Index gets too big
                        }
                    }

                    # For all of the Objects Note Properties, Remove non Latin Characters and HTML Encode the content
                    foreach ($key in $($object | get-member | where-object { $_.MemberType -eq "NoteProperty" }).Name) {
                        if($null -ne $($object.$key)) {
                            $object.$key = $object.$key -creplace '\P{IsBasicLatin}'
                            $object.$key = [System.Net.WebUtility]::HtmlEncode($($object.$key))
                            $object.$key = $($object.$key).replace("`n",'<br/>')
                        }
                    }

                    $retObj.BodyCode += Invoke-TransposeObject -InputObject $objec |  ConvertTo-PshtmlTable

                }
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
