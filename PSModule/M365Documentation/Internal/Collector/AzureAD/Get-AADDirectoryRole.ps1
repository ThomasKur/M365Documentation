Function Get-AADDirectoryRole(){
    <#
    .SYNOPSIS
    This function is used to get the activated directory roles from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the activated directory roles from Azure AD
    .EXAMPLE
    Get-AADDirectoryRole
    Returns the activated directory roles in Azure AD.
    .NOTES
    NAME: Get-AADDirectoryRole
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Directory Roles"
    $DocSec.Text = "List the directory roles that are activated in the tenant."
    $DocSec.Transpose = $false
    $DocSec.SubSections = @()

    $Roles = (Invoke-DocGraph -Path "/directoryRoles").Value
    foreach($Role in $Roles){
        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $Role.displayName
        $DocSecSingle.Text = $Role.description
        $DocSecSingle.SubSections = @()
        try{
            $DocSecSingle.Objects = (Invoke-DocGraph -Path "/directoryRoles/$($Role.id)/members?`$select=displayName,userPrincipalName").Value | Add-ODataTypeToObject -DataType "#microsoft.graph.directoryObject"
        } catch {}
        $DocSecSingle.Transpose = $false
        $DocSec.SubSections += $DocSecSingle
    }
    if($null -eq $DocSec.SubSections){
        return $null
    } else {
        return $DocSec
    }
    
}