<#
.SYNOPSIS
Formats the output as a Format-List style markdown table.

.DESCRIPTION
The Format-MarkdownTableListStyle cmdlet formats the output of a command as a Format-List style markdown table which each property is displayed on a separate col.

Markdown text will be copied to the clipboard.

.PARAMETER InputObject
Specifies the objects to be formatted. Enter a variable that contains the objects or type a command or expression that gets the objects.

.PARAMETER HideStandardOutput
Indicates that the cmdlet hides the standard Format-List style output.

.PARAMETER ShowMarkdown
Indicates that the cmdlet outputs the markdown text to the console.

.PARAMETER DoNotCopyToClipboard
Indicates the the cmdlet does not copy the markdown text to the clipboard.

.PARAMETER Property
Specifies the object properties that appear in the display and the order in which they appear. Wildcards are permitted.

If you omit this parameter, the properties that appear in the display depend on the object being displayed. The parameter name "Property" is optional.

.EXAMPLE
Get-Process notepad | Format-MarkdownTableListStyle

.EXAMPLE
Get-Process notepad | fml Name,Path

.NOTES
You can also refer to Format-MarkdownTableListStyle by its built-in alias, FML.
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.
# https://github.com/microsoft/FormatPowerShellToMarkdownTable

#>
function Format-MarkdownTableListStyle {
    [CmdletBinding()]
    [Alias("fml")]

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
        if ($null -ne $InputObject -and $InputObject.GetType().BaseType -eq [System.Array]) {
            Write-Error "InputObject must not be System.Array. Don't use InputObject, but use the pipeline to pass the array object."
            $NeedToReturn = $true
            return
        }

        $LastCommandLine = (Get-PSCallStack)[1].Position.Text

        $Result = ""

        $TempOutputList = New-Object System.Collections.Generic.List[object]
    }

    Process {
        if ($NeedToReturn) { return }

        $CurrentObject = $null

        if (($Property.Length -eq 0) -or ($Property.Length -eq 1 -and $Property[0] -eq "")) {
            $Property = @("*")
        }

        if ($_ -eq $null) {
            $CurrentObject = $InputObject
        }
        else {
            $CurrentObject = $_
        }

        if ($CurrentObject.GetType().Name.ToLower() -eq "string") {
            # CurrentObject is a simple String object
            # Display like a FT style

            $Output = ""

            if ($Result -eq "") {
                $Output += "||`r`n"
                $Output += "|:--|`r`n"
            }
            
            $Output += "|$(Invoke-EscapeMarkdown($CurrentObject))|`r`n"

            $Result += $Output

            $TempOutputList.Add($CurrentObject)
        }
        else {
            $CurrentObject = $CurrentObject | Select-Object -Property $Property -ErrorAction SilentlyContinue
            $Props = $CurrentObject | Get-Member -Name $Property -MemberType Property, NoteProperty
    
            $Output = "|Property|Value|`r`n"
            $Output += "|:--|:--|`r`n"
    
            $TempOutput = New-Object PSCustomObject
    
            foreach ($Prop in $Props) {
                $EscapedPropName = Invoke-EscapeMarkdown($Prop.Name)
                $EscapedPropValue = Invoke-EscapeMarkdown($CurrentObject.($($Prop.Name)))
                $Output += "|$EscapedPropName|$EscapedPropValue`r`n"
                $TempOutput | Add-Member -MemberType NoteProperty $Prop.Name -Value $CurrentObject.($($Prop.Name)) -Force
            }
    
            $Output += "`r`n"
    
            $Result += $Output
    
            $TempOutputList.Add($TempOutput)
        }
    }
    
    End {
        if ($NeedToReturn) { return }

        $ResultForConsole = $Result
        $Result = "**" + (Invoke-EscapeMarkdown($LastCommandLine)) + "**`r`n`r`n" + $Result

        if ($HideStandardOutput.IsPresent -eq $false) {
            $TempOutputList | Format-List *
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