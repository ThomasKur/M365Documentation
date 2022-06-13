Function Format-MsGraphData(){
    <#
    .SYNOPSIS
    This function Cleansup Values Returned By Microsoft Graph
    .DESCRIPTION
    This function Cleansup Values Returned By Microsoft Graph
    .EXAMPLE
    Format-MsGraphData -Value "@Odata.Type"
    Returns "Type"
    .NOTES
    NAME: Format-MsGraphData
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
    if($null -ne $Value -and $Value -match "@{type=image"){
        $Value = "[Image File]"
    }
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
            Write-Warning "Cannot parse data '$Value' to datetime." -Type Warn
        }
    }
    return $value
}
