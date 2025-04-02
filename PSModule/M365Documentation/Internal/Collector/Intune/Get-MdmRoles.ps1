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
        # Get the Assignments of the Role and put them in a new array (for better readability)
        $RoleAssignments = Invoke-DocGraph -Path "/deviceManagement/roleDefinitions/$($role.id)/roleAssignments" -Beta
        $AssginmentObjects = @()
        foreach($RoleAssignment in $RoleAssignments.value) {
            $AssignmentObject = New-Object -TypeName PSObject

            # List of Role Assignment does not return Members, query again directly with the assignment Id
            $FullRoleAssignment = Invoke-DocGraph -Path "/deviceManagement/roleDefinitions/$($role.id)/roleAssignments/$($RoleAssignment.id)" -Beta | Select-Object -Property displayName, description, resourceScopes, scopeMembers, scopeType, members
            $AssignmentObject | Add-Member -MemberType NoteProperty -Name "Assignment displayName" -Value $FullRoleAssignment.displayName
            $AssignmentObject | Add-Member -MemberType NoteProperty -Name "Assignment description" -Value $FullRoleAssignment.description

            # Members, Scope Members and resourceScopes only return member IDs. Resolve the directory objects, put them in a string and separate them by linebreak
            $AssignmentObject | Add-Member -MemberType NoteProperty -Name "Members" -Value @()
            foreach($member in $FullRoleAssignment.members) {
                $req = Invoke-DocGraph -Path "/directoryObjects/$member" | select '@odata.type', "id", "displayName"
                $AssignmentObject.Members += "$($req.displayName) ($($req.'@odata.type'))"
            }
            $AssignmentObject.Members = $AssignmentObject.Members -join " "
            
            $AssignmentObject | Add-Member -MemberType NoteProperty -Name "scopeMembers" -Value @()
            foreach($scopemember in $FullRoleAssignment.scopeMembers) {
                $req = Invoke-DocGraph -Path "/directoryObjects/$scopemember" | select '@odata.type', "id", "displayName"
                $AssignmentObject.scopeMembers += "$($req.displayName) ($($req.'@odata.type'))"
            }
            $AssignmentObject.scopeMembers = $AssignmentObject.scopeMembers -join " "

            $AssignmentObject | Add-Member -MemberType NoteProperty -Name "resourceScopes" -Value @()
            foreach($resourceScope in $FullRoleAssignment.resourceScopes) {
                $req = Invoke-DocGraph -Path "/directoryObjects/$resourceScope" | select '@odata.type', "id", "displayName"
                $AssignmentObject.resourceScopes += "$($req.displayName) ($($req.'@odata.type'))"
            }
            $AssignmentObject.resourceScopes = $AssignmentObject.resourceScopes -join " "

            # Finally, add the Object to the array
            $AssginmentObjects += $AssignmentObject
        }

        # Create Doc Object
        $DocSecSingle = New-Object DocSection
        $DocSecSingle.Title = $Role.displayName
        $DocSecSingle.Text = $Role.description
        $DocSecSingle.Transpose = $false

        # Now, if we have a built in Role, we only need the assignments. If we have a custom role, we create new subsections and document the permissions and assignments
        if($role.isBuiltIn -eq $true) {
            $DocSecSingle.Title = $DocSecSingle.Title + " (BuiltIn)"
            $DocSecSingle.SubSections = @()
            $DocSecSingle.Objects = $AssginmentObjects
        }
        else {
            $DocSecSingle.Title = $DocSecSingle.Title + " (Custom Role)"
            $DocSecSingle.SubSections = @()
            $DocSecSingle.Objects = @()

            # Create an object for the permissions (with transpose), and add it as subsection
            $DocSecPermissions = New-Object DocSection
            $DocSecPermissions.Title = "Permissions"
            $DocSecPermissions.Text = "Defined permissions for the configured role"
            $DocSecPermissions.Transpose = $false
            
            # Add the permissions to an object for a nicer look in the Docs
            $permissionObjects = @()
            foreach ($permission in $role.rolePermissions.resourceActions.allowedResourceActions) {
                $permissionObject = New-Object -TypeName psobject
                $permissionObject | Add-Member -MemberType NoteProperty -Name "Permission" -Value $permission
                $permissionObject | Add-Member -MemberType NoteProperty -Name "Status" -Value "Enabled"
                $permissionObjects += $permissionObject
            }
            $DocSecPermissions.Objects = $permissionObjects
            $DocSecSingle.SubSections += $DocSecPermissions

            # Create an object for the assignments and add it as subsection
            $DocSecAssignments = New-Object DocSection
            $DocSecAssignments.Title = "Assignements"
            $DocSecAssignments.Text = $null
            $DocSecAssignments.Transpose = $false
            $DocSecAssignments.Objects = $AssginmentObjects
            $DocSecSingle.SubSections += $DocSecAssignments
        }
        
        $DocSec.SubSections += $DocSecSingle
    } 

    return $DocSec
}