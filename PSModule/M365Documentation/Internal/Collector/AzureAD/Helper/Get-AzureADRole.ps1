Function Get-AzureADRole(){
    <#
    .SYNOPSIS
    This function is used to get the AzureAD Role Name by ID from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Azure AD Role Name
    .EXAMPLE
    Get-AzureADRole -RoleId 162358712538975698
    Returns the Role Name for the given Role id
    .NOTES
    NAME: Get-AzureADRole
    #>
    param(
            [String]
            $RoleId
        )
    
    if($RoleId -match("^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$")){
        (Invoke-DocGraph -Path "/directoryRoleTemplates/$RoleId" -Beta).displayName
    } else {
        $RoleId
    }
    
}