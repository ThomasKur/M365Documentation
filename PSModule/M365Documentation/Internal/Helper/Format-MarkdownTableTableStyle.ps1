<#
.SYNOPSIS
Formats the output as a Format-Table style markdown table.

.DESCRIPTION
The Format-MarkdownTableTableStyle cmdlet formats the output of a command as a Format-Table style markdown table which each property is displayed on a separate row.

Markdown text will be copied to the clipboard.

.PARAMETER InputObject
Specifies the objects to be formatted. Enter a variable that contains the objects or type a command or expression that gets the objects.

.PARAMETER HideStandardOutput
Indicates that the cmdlet hides the standard Format-Table style output.

.PARAMETER ShowMarkdown
Indicates that the cmdlet outputs the markdown text to the console.

.PARAMETER DoNotCopyToClipboard
Indicates the the cmdlet does not copy the markdown text to the clipboard.

.PARAMETER Property
Specifies the object properties that appear in the display and the order in which they appear. Wildcards are permitted.

If you omit this parameter, the properties that appear in the display depend on the object being displayed. The parameter name "Property" is optional.

.EXAMPLE
Get-Process notepad | Format-MarkdownTableTableStyle

.EXAMPLE
Get-Process notepad | fmt Name,Path

.NOTES
You can also refer to Format-MarkdownTableTableStyle by its built-in alias, FMT.
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.
# https://github.com/microsoft/FormatPowerShellToMarkdownTable

#>
function Format-MarkdownTableTableStyle {
    [CmdletBinding()]
    [Alias("fmt")]

    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]
        $InputObject,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [switch]
        $HideStandardOutput,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [switch]
        $ShowMarkdown,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [switch]
        $DoNotCopyToClipboard,

        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $false)]
        [string[]]
        $Property = @()
    )
    
    Begin {
        ## Internal Function

        function UseAllProperty([object]$InputObject) {
            try {
                if ($null -eq $InputObject) {
                    return $true
                }
    
                $DataType = ($InputObject | Get-Member)[0].TypeName
    
                if ($DataType.StartsWith("Selected.")) {
                    return $true
                }            
                elseif ($DataType.StartsWith("Deserialized.")) {
                    $DataType = $DataType.Remove(0, 13)
                }
    
                $FormatData = Get-FormatData -TypeName $DataType -ErrorAction SilentlyContinue
    
                if ($null -eq $FormatData) {
                    return $true
                }
    
                return $false
            }
            catch {
                return $true
            }
        }
        
        if ($null -ne $InputObject -and $InputObject.GetType().BaseType -eq [System.Array]) {
            Write-Error "InputObject must not be System.Array. Don't use InputObject, but use the pipeline to pass the array object."
            $NeedToReturn = $true
            return
        }

        $LastCommandLine = (Get-PSCallStack)[1].Position.Text

        $Result = ""

        $HeadersForFormatTableStyle = New-Object System.Collections.Generic.List[string]
        $ContentsForFormatTableStyle = New-Object System.Collections.Generic.List[object]

        $TempOutputList = New-Object System.Collections.Generic.List[object]
    }

    Process {
        if ($NeedToReturn) { return }

        $CurrentObject = $null

        if ($_ -eq $null) {
            $CurrentObject = $InputObject
        }
        else {
            $CurrentObject = $_
        }

        if ($CurrentObject.GetType().Name.ToLower() -eq "string") {
            # CurrentObject is a simple String object
            $Props = @("")
        }
        elseif (($Property.Length -eq 0) -or ($Property.Length -eq 1 -and $Property[0] -eq "")) {
            if (UseAllProperty($CurrentObject)) {
                $Property = @("*")
                $CurrentObject = $CurrentObject | Select-Object -Property $Property
                $Props = $CurrentObject | Get-Member -Name $Property -MemberType Property, NoteProperty
            }
            else {
                $DataType = ($CurrentObject | Get-Member)[0].TypeName
        
                if ($DataType.StartsWith("Deserialized.")) {
                    $DataType = $DataType.Remove(0, 13)
                }
        
                $FormatData = Get-FormatData -TypeName $DataType -ErrorAction SilentlyContinue
                
                $TempPSObject = New-Object PSCustomObject

                $TempHeaderList = New-Object System.Collections.Generic.List[string]

                if ($FormatData.FormatViewDefinition.Control.Headers)
                {
                    for ($i = 0; $i -lt $FormatData.FormatViewDefinition.Control.Headers.Count; $i++) {
                        $HeaderName = $FormatData.FormatViewDefinition.Control.Headers[$i].Label
    
                        if ($null -eq $HeaderName -or $HeaderName -eq "") {
                            $HeaderName = $FormatData.FormatViewDefinition.Control.Rows.Columns[$i].DisplayEntry.Value
                        }
    
                        $TempSelectedObject = $null
    
                        if ($FormatData.FormatViewDefinition.Control.Rows.Columns[$i].DisplayEntry.ValueType -eq "ScriptBlock") {
                            $TempSelectedObject = $CurrentObject | Select-Object @{
                                n = $HeaderName;
                                e = ([scriptblock]::Create($FormatData.FormatViewDefinition.Control.Rows.Columns[$i].DisplayEntry.Value))
                            }
                        }
                        else {
                            $PropertyName = $FormatData.FormatViewDefinition.Control.Rows.Columns[$i].DisplayEntry.Value
    
                            $TempSelectedObject = $CurrentObject | Select-Object @{
                                n = $HeaderName;
                                e = {$_.$($PropertyName)}
                            }
                        }
    
                        $Value = $TempSelectedObject.$($HeaderName)
                        $TempPSObject | Add-Member -MemberType NoteProperty $HeaderName -Value $Value
                        $TempHeaderList.Add($HeaderName)
                    }
                }
                else {
                    for ($i = 0; $i -lt $FormatData.FormatViewDefinition.Control.Entries.Items.Count; $i++) {
                        $HeaderName = $FormatData.FormatViewDefinition.Control.Entries.Items[$i].DisplayEntry.Value

                        $TempSelectedObject = $null

                        $TempSelectedObject = $CurrentObject | Select-Object @{
                            n = $HeaderName;
                            e = {$_.$($HeaderName)}
                        }

                        $Value = $TempSelectedObject.$($HeaderName)
                        $TempPSObject | Add-Member -MemberType NoteProperty $HeaderName -Value $Value
                        $TempHeaderList.Add($HeaderName)
                    }
                }

                $CurrentObject = $TempPSObject | Select-Object -Property $TempHeaderList
                $Props = $CurrentObject | Get-Member -Name $TempHeaderList -MemberType Property, NoteProperty
            }
        }
        else {
            $CurrentObject = $CurrentObject | Select-Object -Property $Property -ErrorAction SilentlyContinue
            $Props = $CurrentObject | Get-Member -Name $Property -MemberType Property, NoteProperty
        }

        foreach ($Prop in $Props) {
            if ($HeadersForFormatTableStyle.Contains($Prop.Name) -eq $false) {
                $HeadersForFormatTableStyle.Add($Prop.Name)
            }
        }

        $ContentsForFormatTableStyle.Add($CurrentObject)
    }
    
    End {
        if ($NeedToReturn) { return }

        $HeaderRow = "|"
        $SeparatorRow = "|"
        $ContentRow = ""

        foreach ($Prop in $HeadersForFormatTableStyle) {
            $HeaderRow += "$(Invoke-EscapeMarkdown($Prop))|"
            $SeparatorRow += ":--|"
            
        }

        foreach ($Content in $ContentsForFormatTableStyle) {
            $TempOutput = New-Object PSCustomObject
            $ContentRow += "|"

            if ($HeadersForFormatTableStyle.Count -eq "1" -and $HeadersForFormatTableStyle[0] -eq "") {
                # Content is an array of simple data type, like String.
                $ContentRow += "$(Invoke-EscapeMarkdown($Content))|"
                $TempOutput = $null
                $TempOutput = $Content
            }
            else {
                foreach ($Prop in $HeadersForFormatTableStyle) {
                    $ContentRow += "$(Invoke-EscapeMarkdown($Content.($($Prop))))|"
    
                    $TempOutput | Add-Member -MemberType NoteProperty $Prop -Value $Content.($($Prop))
                }
            }
            
            $ContentRow += "`r`n"

            $TempOutputList.Add($TempOutput)
        }

        $Result = $HeaderRow + "`r`n" + $SeparatorRow + "`r`n" + $ContentRow

        $ResultForConsole = $Result
        $Result = "**" + (Invoke-EscapeMarkdown($LastCommandLine)) + "**`r`n`r`n" + $Result

        if ($HideStandardOutput.IsPresent -eq $false) {
            $TempOutputList | Format-Table * -AutoSize
        }

        if ($ShowMarkdown.IsPresent) {
            Write-Output $ResultForConsole
        }

        if ($DoNotCopyToClipboard.IsPresent -eq $false) {
            Set-Clipboard $Result
            Write-Warning "Markdown text has been copied to the clipboard."
        }
    }
}