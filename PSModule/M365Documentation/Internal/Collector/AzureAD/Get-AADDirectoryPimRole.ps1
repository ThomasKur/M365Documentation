Function Get-AADDirectoryPimRole(){
    <#
    .SYNOPSIS
    This function is used to get the eligible assigned directory roles from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the eligible assigned directory roles from Azure AD
    .EXAMPLE
    Get-AADDirectoryPimRole
    Returns the eligible assigned directory roles in Azure AD.
    .NOTES
    NAME: Get-AADDirectoryPimRole
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "PIM Directory Roles"
    $DocSec.Text = "List the directory roles that are eligible assigned in the tenant."
    $DocSec.Transpose = $false
    $DocSec.SubSections = @()

    $Roles = (Invoke-DocGraph -Path "/directoryRoles").Value
    $PimRoles = (Invoke-DocGraph -Path "/roleManagement/directory/roleEligibilitySchedules").Value
    foreach($Role in $Roles){
        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $Role.displayName
        $DocSecSingle.Text = $Role.description
        $DocSecSingle.SubSections = @()

        $pimAssignments = $pimRoles | Where-Object { $_.roleDefinitionId -eq $Role.roleTemplateId }
        $DocSecSingle.Objects =  foreach($pimAssignment in $pimAssignments) {
            (Invoke-DocGraph -Path "/directoryObjects/$($pimAssignment.principalId)") | Select-Object displayName, id, "@odata.type"
        }

        $DocSecSingle.Transpose = $false
        $DocSec.SubSections += $DocSecSingle
    }
    if($null -eq $DocSec.SubSections){
        return $null
    } else {
        return $DocSec
    }
    
}