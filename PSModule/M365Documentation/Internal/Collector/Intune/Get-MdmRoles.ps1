Function Get-MdmRoles(){
    <#
    .SYNOPSIS
    This function is used to get the all device management roles and assignments Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the device management roles and their assignments
    .EXAMPLE
    Get-MdmRoles
    Returns the device management roles and assignments
    .NOTES
    NAME: Get-MdmRoles
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Device Management Roles"
    $DocSec.Text = "This section contains all device management roles and assignments."

    $Roles = Invoke-DocGraph -Path "/deviceManagement/roleDefinitions"
    foreach($Role in $Roles.Value){
        
        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $Role.displayName
        $DocSecSingle.Text = $Role.description
        $DocSecSingle.SubSections = @()

        $AssginmentObjects = @()

        $RoleAssignments = Invoke-DocGraph -Path "/deviceManagement/roleDefinitions/$($role.id)/roleAssignments" -Beta
        foreach($RoleAssignment in $RoleAssignments.value) {
            $AssignmentObject = New-Object -TypeName PSObject

            # List of Role Assignment does not return Members, query again directly with the assignment Id
            $FullRoleAssignment = Invoke-DocGraph -Path "/deviceManagement/roleDefinitions/$($role.id)/roleAssignments/$($RoleAssignment.id)" -Beta | Select-Object -Property displayName, description, resourceScopes, scopeMembers, scopeType, members
            $AssignmentObject | Add-Member -MemberType NoteProperty -Name "Assignment displayName" -Value $FullRoleAssignment.displayName
            $AssignmentObject | Add-Member -MemberType NoteProperty -Name "Assignment description" -Value $FullRoleAssignment.description

            $AssignmentObject | Add-Member -MemberType NoteProperty -Name "Members" -Value @()
            foreach($member in $FullRoleAssignment.members) {
                $req = Invoke-DocGraph -Path "/directoryObjects/$member" | select '@odata.type', "id", "displayName"
                $AssignmentObject.Members += $($req.'@odata.type') + " " + $($req.id) + " " + $($req.displayName)
            }
            $AssignmentObject.Members = $AssignmentObject.Members -join "`r`n"
            
            $AssignmentObject | Add-Member -MemberType NoteProperty -Name "scopeMembers" -Value @()
            foreach($scopemember in $FullRoleAssignment.scopeMembers) {
                $req = Invoke-DocGraph -Path "/directoryObjects/$scopemember" | select '@odata.type', "id", "displayName"
                $AssignmentObject.scopeMembers += $($req.'@odata.type') + " " + $($req.id) + " " + $($req.displayName)
            }
            $AssignmentObject.scopeMembers = $AssignmentObject.scopeMembers -join "`r`n"

            $AssignmentObject | Add-Member -MemberType NoteProperty -Name "resourceScopes" -Value @()
            foreach($resourceScope in $FullRoleAssignment.resourceScopes) {
                $req = Invoke-DocGraph -Path "/directoryObjects/$resourceScope" | select '@odata.type', "id", "displayName"
                $AssignmentObject.resourceScopes += $($req.'@odata.type') + " " + $($req.id) + " " + $($req.displayName)
            }
            $AssignmentObject.resourceScopes = $AssignmentObject.resourceScopes -join "`r`n"

            $AssginmentObjects += $AssignmentObject
        }

        $DocSecSingle.Objects = $AssginmentObjects
        $DocSecSingle.Transpose = $false
        $DocSec.SubSections += $DocSecSingle
    } 

    return $DocSec
}