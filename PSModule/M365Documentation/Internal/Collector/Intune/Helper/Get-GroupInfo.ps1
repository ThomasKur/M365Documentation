Function Get-GroupInfo(){
    <#
    .SYNOPSIS
    This function retrieves details about AAD groups.
    .DESCRIPTION
    This function retrieves details about AAD groups and return a DocSection.
    .EXAMPLE
    Get-GroupInfo -GroupIds $groupIds
    Returns the information from the Group

    .OUTPUTS
    Outputs custom objects with the following structure:
    - Name
    - MemberCount
    - GroupType
    - DynamicRule

    .NOTES
    NAME: Thomas Kurth 5.3.2021
    #>
    param(
        [Parameter(Mandatory=$true, ParameterSetName = "Id")]
        [int[]]$GroupIds,
        [Parameter(Mandatory=$true, ParameterSetName = "Groups")]
        [Object[]]$Groups
    )
    $returnObjs = @()
    $GroupObjs = @()
    if($PSCmdlet.ParameterSetName -eq "Id"){
        foreach($GroupId in ($GroupIds | Select-Object -Unique)){
            $GroupObj = Invoke-DocGraph -Path "/groups/$($GroupId)" 
            $GroupObjs += $GroupObj
        }
    } else {
        $GroupObjs = $Groups
    }
    
    foreach($GroupObj in ($GroupObjs | Select-Object -Unique)){
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
        $Members = Invoke-DocGraph -Path "/groups/$($GroupObj.Id)/transitiveMembers?`$select=displayName"
        if($null -eq $Members.value.count){
            if($null -eq $Members){
                $MemberCount = 1
            } else {
                $MemberCount = 0
            }
        } else {
            $MemberCount = $Members.value.count
        }
        $DynamicRule = $GroupObj.membershipRule
        if($null -eq $DynamicRule){
            $DynamicRule = "-"
        }
        $returnObjs +=[PSCustomObject]@{
            Name = $Name
            MemberCount = $MemberCount
            GroupType = $GType
            DynamicRule = $DynamicRule
        }
    }
    return $returnObjs
}