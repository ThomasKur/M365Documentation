Function Invoke-TranslateSimple(){
    <#
    .SYNOPSIS
    This function Cleans-up Values Returned By Microsoft Graph
    .DESCRIPTION
    This function Cleans-up Values Returned By Microsoft Graph
    .EXAMPLE
    Invoke-TranslateSimple
    Returns "Type"
    .NOTES
    NAME: Invoke-TranslateSimple
    #>
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [AllowNull()]
        $Value
    )
    $DateTimeRegex = "\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{7}Z" 
    if($value -is [array]){
        $value = $value -join ","
    }
    [string]$value = "$value"
    $Value = $Value -replace "#microsoft.graph.",""
    $Value = $Value -replace "windows","win"
    $Value = $Value -replace "StoreforBusiness","SfB"
    $Value = $Value -replace "@odata.",""
    if($null -ne $Value -and $Value -match "@{*"){
        $Value = $Value -replace "@{",""
        $Value = $Value -replace "}",""
        $Value = $Value -replace ";",""
    }
    if($Value -match $DateTimeRegex){
        try{
            [DateTime]$Date = ([DateTime]::Parse($Value))
            $Value = "$($Date.ToShortDateString()) $($Date.ToShortTimeString())"
        } catch {
            Write-Warning "Cannot parse data" -WarningAction Continue
        }
    }
    return $value
}