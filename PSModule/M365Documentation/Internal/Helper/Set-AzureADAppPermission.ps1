Function Set-AzureADAppPermission
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param
    (
        [string] $targetServicePrincipalName,
        $appPermissionsRequired,
        $childApp,
        $spForApp
    )
    if ($PSCmdlet.ShouldProcess("Target", "Operation"))
		{
        $targetSp = Get-AzureADServicePrincipal -Filter "DisplayName eq '$($targetServicePrincipalName)'"

        # Iterate Permissions array
        Write-Verbose ('Retrieve Role Assignments objects')
        $RoleAssignments = @()
        Foreach ($AppPermission in $appPermissionsRequired) {
            $RoleAssignment = $targetSp.AppRoles | Where-Object { $_.Value -eq $AppPermission}
            $RoleAssignments += $RoleAssignment
        }

        $ResourceAccessObjects = New-Object 'System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.ResourceAccess]'
        foreach ($RoleAssignment in $RoleAssignments) {
            $resourceAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess"
            $resourceAccess.Id = $RoleAssignment.Id
            $resourceAccess.Type = 'Role'
            $ResourceAccessObjects.Add($resourceAccess)
        }
        $requiredResourceAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
        $requiredResourceAccess.ResourceAppId = $targetSp.AppId
        $requiredResourceAccess.ResourceAccess = $ResourceAccessObjects

        # set the required resource access
        Set-AzureADApplication -ObjectId $childApp.ObjectId -RequiredResourceAccess $requiredResourceAccess 
        Start-Sleep -s 1

        # grant the required resource access
        foreach ($RoleAssignment in $RoleAssignments) {
            Write-Verbose ('Granting admin consent for App Role: {0}' -f $($RoleAssignment.Value))
            New-AzureADServiceAppRoleAssignment -ObjectId $spForApp.ObjectId -Id $RoleAssignment.Id -PrincipalId $spForApp.ObjectId -ResourceId $targetSp.ObjectId
            Start-Sleep -s 1
        }
    } else  {
        Write-Information "Create Azure AD Application and set permission."
    }
}