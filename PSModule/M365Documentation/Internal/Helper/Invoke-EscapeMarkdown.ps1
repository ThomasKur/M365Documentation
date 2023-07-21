function Invoke-EscapeMarkdown([object]$InputObject) {
    $Temp = ""

    if ($null -eq $InputObject) {
        return ""
    }
    elseif ($InputObject.GetType().BaseType -eq [System.Array]) {
        $Temp = "{" + [System.String]::Join(", ", $InputObject) + "}"
    }
    elseif ($InputObject.GetType() -eq [System.Collections.ArrayList] -or $InputObject.GetType().ToString().StartsWith("System.Collections.Generic.List")) {
        $Temp = "{" + [System.String]::Join(", ", $InputObject.ToArray()) + "}"
    }
    elseif (Get-Member -InputObject $InputObject -Name ToString -MemberType Method) {
        $Temp = $InputObject.ToString()
    }
    else {
        $Temp = ""
    }

    return $Temp.Replace("\", "\\").Replace("*", "\*").Replace("_", "\_").Replace("``", "\``").Replace("$", "\$").Replace("|", "\|").Replace("<", "\<").Replace(">", "\>").Replace([System.Environment]::NewLine, "<br />")
}