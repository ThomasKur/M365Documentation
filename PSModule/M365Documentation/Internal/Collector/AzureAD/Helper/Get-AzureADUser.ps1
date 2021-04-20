Function Get-AzureADUser(){
    <#
    .SYNOPSIS
    This function is used to get the AzureAD User Name by ID from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Azure AD User Name
    .EXAMPLE
    Get-AzureADUser -UserId 162358712538975698
    Returns the User Name for the given User id
    .NOTES
    NAME: Get-AzureADUser
    #>
    param(
            [String]
            $UserId
        )
    
    if($UserId -match("^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$")){
        $user = (Invoke-DocGraph -Path "/users/$UserId" -Beta)
        "$($user.displayName)($($user.userPrincipalName))"
    } else{
        $UserId
    }
    
}