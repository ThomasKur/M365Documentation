Function Get-AssignmentDetailSingle(){
    <#
    .SYNOPSIS
    This function is used to collect information about assignment and the group.
    .DESCRIPTION
    This function is used to collect information about assignment and the group.
    .EXAMPLE
    Get-AssignmentDetailSingle -Assignment $assignment
    Returns the information from the Assignent

    .OUTPUTS
    Outputs a custom object with the following structure:
    - Name
    - MemberCount
    - Type
    - DynamicRule

    .NOTES
    NAME: Get-AssignmentDetailSingle 
    #>
    param(
        $Assignment
    )
    if($null -ne $Assignment.target.groupId){
        $GroupObj = Invoke-DocGraph -Path "/groups/$($Assignment.target.groupId)"  
        $Name = $GroupObj.displayName
        if($GroupObj.groupTypes -contains "DynamicMembership"){
            if($GroupObj.membershipRule -like "*user.*"){
                $GType = "DynamicUser"
            } else {
                $GType = "DynamicDevice"
            }
        } else {
            $GType = "Static"
        }
        $Members = Invoke-DocGraph -Path "/groups/$($Assignment.target.groupId)/transitiveMembers?`$select=displayName"
        if($null -eq $Members.count){
            if($null -eq $Members){
                $MemberCount = 1
            } else {
                $MemberCount = 0
            }
        } else {
            $MemberCount = $Members.count
        }
        $DynamicRule = $GroupObj.membershipRule
        if($null -eq $DynamicRule){
            $DynamicRule = "-"
        }
        $returnObj =[PSCustomObject]@{
            Name = $Name
            MemberCount = $MemberCount
            GroupType = $GType
            DynamicRule = $DynamicRule
            Intent = "-"
            Source = ""
            AssignType = "Include"
        }
    } else {

        $Name = "$(($Assignment.target.'@odata.type' -replace "#microsoft.graph.",''))"
        switch ( $Name )
        {
            "allDevicesAssignmentTarget" { $Name = "All Devices" }
            "allLicensedUsersAssignmentTarget" { $Name = "All Users"  }
        }
        
        $returnObj =[PSCustomObject]@{
            Name = $Name
            MemberCount = "-"
            GroupType = "BuilIn"
            DynamicRule = "-"
            Intent = "-"
            Source = ""
            AssignType = "Include"
        }
    } 

    #Intent if Available
    if($null -ne $Assignment.intent){
        $returnObj.Intent = $Assignment.intent
    } 
    # Source
    if($null -ne $Assignment.source){
        $returnObj.Source = $Assignment.source
    } 
    # Include or Exclude
    if($Assignment.target.'@odata.type' -like "*exclu*"){
        $returnObj.AssignType = "Exclude"
    } 

    $returnObj
}