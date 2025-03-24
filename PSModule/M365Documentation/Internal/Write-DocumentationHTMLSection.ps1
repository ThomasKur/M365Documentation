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

    $retObj = New-Object -TypeName PSObject
    $retObj | Add-Member -MemberType NoteProperty -Name "IndexCode" -Value ""
    $retObj | Add-Member -MemberType NoteProperty -Name "BodyCode" -Value ""

    if($Data.Objects -or $Data.SubSections){
        $TitleClean = $Data.Title.ToLower().Replace(" ","-") -replace '[^a-zA-Z0-9/_/-]', ''
        if($data.Transpose -eq $true) { $Transpose = $true }

        if($Data.Objects){  
            $retObj.BodyCode += "<h3 id=""$titleClean"">$($Section.Title)</h3><p>$($Section.Text)</p>"
            $retObj.IndexCode += "<li><a href=""#$TitleClean"">$($Section.Title)</a></li>"

            if($Transpose -eq $true) { 
                $subindex = "<ul>"
                foreach($object in $data.Objects) {
                    if($object.displayName -or $object.M_DisplayName) {
                        if($object.displayName) { $dn = $object.displayName}
                        else {$dn = $object.M_DisplayName }
                        $displayNameClean = $Data.Title.ToLower().Replace(" ","-") -replace '[^a-zA-Z0-9/_/-]', ''
                        $retObj.BodyCode += "<p id=""$displayNameClean"">$dn</p>"
                        $retObj.IndexCode += "<li><a href=""#$displayNameClean"">$dn</a></li>"
                    }
                    $retObj.BodyCode += Invoke-TransposeObject -InputObject $object |  ConvertTo-PshtmlTable

                }
                $subindex += "</ul>"
            }
            else {
                $retObj.BodyCode += $data.Objects |  ConvertTo-PshtmlTable
            }
        }
        else {
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
