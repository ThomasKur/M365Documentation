function Get-ValidComponentsValue {
    [CmdletBinding()]
    param()
    $AllCommands = Get-ChildItem -Path "$PSScriptRoot\..\Internal\Collector" -Directory 
    return $AllCommands.Name
}

Function Get-M365DocValidSection(){
    <#
    .DESCRIPTION
    This Script returns possible values for the Section (ExcludeSections and IncludeSections) Parameter of the Get-M365Doc command.

    .PARAMETER Components
        The components for which the available sections should be returned.
     

    .EXAMPLE Get List of Valid Sections for Intune
    Get-M365DocValidSection -Components Intune

    .EXAMPLE Get List of Valid Sections for Intune and Exchange
    Get-M365DocValidSection -Components Intune,Exchange

    .Example Use in Get-M365Doc with Out-GridView allowing selection of sections
    $Sections = Get-M365DocValidSection -Components Intune | Out-GridView -OutputMode Multiple | Select-Object -ExpandProperty SectionName
    $doc = Get-M365Doc -Components Intune -IncludeSections $Sections

    .NOTES
    Author: Thomas Kurth/baseVISION
    Date:   27.03.2025

    History
        See Release Notes in Github.

    #>
    [OutputType("String[]")]
    Param(
        [ArgumentCompleter(
            {
                param(
                    $Command, 
                    $Parameter, 
                    $WordToComplete, 
                    $CommandAst, 
                    $FakeBoundParams)

                Get-ValidComponentsValue 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-ValidComponentsValue)
            }
        )]
        [string[]]$Components

    )
    ## Manual Variable Definition
    ########################################################
    #$DebugPreference = "Continue"
    $ScriptName = "Get-ValidSectionValue"

    #region Initialization
    ########################################################
    Write-Verbose "Start Script $Scriptname"
    
    #endregion
    $Sections = @()
    if($null -eq $Components){
        $Components = Get-ValidComponentsValue
    }
    foreach($Component in $Components){
        $AllCommands = Get-ChildItem -Path "$PSScriptRoot\..\Internal\Collector\$Component" -File -Recurse -Depth 1
        foreach($Command in $AllCommands){
            $Sections += [pscustomobject]@{
                SectionName = $Command.Name.Replace(".ps1", "").Replace("Get-", "")
                Component = $Component
            }
        }
    }

    #region Finishing
    ########################################################
    
    return $Sections
    
    Write-Information "End Script $Scriptname"
    #endregion
}
