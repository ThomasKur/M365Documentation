Function Get-AzureADApplicationName(){
    <#
    .SYNOPSIS
    This function is used to get the AzureAD Application Name by ID from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Azure AD Application Name
    .EXAMPLE
    Get-AzureADApplicationName -AppId 162358712538975698
    Returns the Application Name for the given Application id
    .NOTES
    NAME: Get-AzureADApplicationName
    #>
    param(
            [String]
            $AppId
        )

    if($AppId -match("^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$")){
        $app = (Invoke-DocGraph -Path "/servicePrincipals?`$Filter=appId%20eq%20%27$AppId%27" -Beta).Value[0]
        "$($app.displayName)($AppId)"
    } else {
        $AppId
    }

}