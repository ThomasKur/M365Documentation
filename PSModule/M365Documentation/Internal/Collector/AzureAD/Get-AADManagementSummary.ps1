Function Get-AADManagementSummary(){
    <#
    .SYNOPSIS
    This function provides a management summary for Entra ID (Azure AD).
    .DESCRIPTION
    The function collects key Entra ID summary metrics including identity inventory,
    conditional access posture, directory role assignments, and authentication method policy states.
    .EXAMPLE
    Get-AADManagementSummary
    Returns a management summary section for Entra ID.
    .NOTES
    NAME: Get-AADManagementSummary
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    function ConvertTo-Array {
        param([object]$InputObject)

        if($null -eq $InputObject){
            return @()
        }

        if($InputObject.PSObject.Properties.Name -contains "value"){
            if($null -eq $InputObject.value){
                return @()
            }

            if($InputObject.value -is [System.Array]){
                return $InputObject.value
            }

            return @($InputObject.value)
        }

        if($InputObject -is [System.Array]){
            return $InputObject
        }

        return @($InputObject)
    }

    function Get-PolicyStateGroup {
        param([string]$State)

        if([string]::IsNullOrWhiteSpace($State)){
            return "Unknown"
        }

        $value = $State.ToLowerInvariant()
        if($value -eq "enabled"){
            return "Enabled"
        }

        if($value -eq "disabled"){
            return "Disabled"
        }

        if($value -match "report"){
            return "ReportOnly"
        }

        return $State
    }

    function Get-MethodPolicyState {
        param([object]$MethodPolicy)

        if($null -eq $MethodPolicy){
            return "Unknown"
        }

        if($MethodPolicy.PSObject.Properties.Name -contains "state" -and -not [string]::IsNullOrWhiteSpace("$($MethodPolicy.state)")){
            return "$($MethodPolicy.state)"
        }

        if($MethodPolicy.PSObject.Properties.Name -contains "isUsableForSignIn" -and $null -ne $MethodPolicy.isUsableForSignIn){
            if([bool]$MethodPolicy.isUsableForSignIn){
                return "enabled"
            }

            return "disabled"
        }

        if($MethodPolicy.PSObject.Properties.Name -contains "isSoftwareOathEnabled" -and $null -ne $MethodPolicy.isSoftwareOathEnabled){
            if([bool]$MethodPolicy.isSoftwareOathEnabled){
                return "enabled"
            }

            return "disabled"
        }

        return "Unknown"
    }

    function ConvertTo-DateTimeOrNull {
        param([object]$Value)

        if($null -eq $Value -or [string]::IsNullOrWhiteSpace("$Value")){
            return $null
        }

        try {
            return [datetime]$Value
        } catch {
            return $null
        }
    }

    $DocSec = New-Object DocSection
    $DocSec.Title = "Management Summary - Entra ID"
    $DocSec.Text = "This section contains an Entra ID management summary with key identity, policy, and role metrics."
    $DocSec.SubSections = @()

    $organization = $null
    $nowUtc = (Get-Date).ToUniversalTime()
    $staleGuestThresholdDays = 90
    $credentialExpiryThresholdDays = 30
    $users = @()
    $groups = @()
    $servicePrincipals = @()
    $applications = @()
    $conditionalAccessPolicies = @()
    $directoryRoles = @()
    $roleMemberSummary = @()
    $staleGuestUsers = 0
    $neverSignedInStaleGuests = 0
    $credentialsExpiringSoon = 0
    $expiredCredentials = 0
    $appsWithExpiringCredentials = @{}

    try {
        $organization = ConvertTo-Array (Invoke-DocGraph -Path "/organization?`$select=id,displayName,tenantType" -FollowNextLink $true) | Select-Object -First 1
    } catch {
        Write-Warning "Unable to collect organization summary."
    }

    try {
        $users = ConvertTo-Array (Invoke-DocGraph -Path "/users?`$select=id,userType,accountEnabled" -FollowNextLink $true)
    } catch {
        Write-Warning "Unable to collect user inventory summary."
    }

    try {
        $guestUsersWithActivity = ConvertTo-Array (Invoke-DocGraph -Path "/users?`$select=id,displayName,userPrincipalName,userType,createdDateTime,signInActivity&`$filter=userType%20eq%20'Guest'" -Beta -FollowNextLink $true)
        foreach($guest in $guestUsersWithActivity){
            $createdDate = ConvertTo-DateTimeOrNull -Value $guest.createdDateTime
            $lastSignInDate = $null
            if($guest.PSObject.Properties.Name -contains "signInActivity" -and $null -ne $guest.signInActivity){
                $lastSignInDate = ConvertTo-DateTimeOrNull -Value $guest.signInActivity.lastSignInDateTime
            }

            if($null -ne $lastSignInDate){
                $daysSinceSignIn = [Math]::Floor(($nowUtc - $lastSignInDate.ToUniversalTime()).TotalDays)
                if($daysSinceSignIn -ge $staleGuestThresholdDays){
                    $staleGuestUsers++
                }
            } elseif($null -ne $createdDate) {
                $daysSinceCreated = [Math]::Floor(($nowUtc - $createdDate.ToUniversalTime()).TotalDays)
                if($daysSinceCreated -ge $staleGuestThresholdDays){
                    $staleGuestUsers++
                    $neverSignedInStaleGuests++
                }
            }
        }
    } catch {
        Write-Warning "Unable to collect stale guest account findings."
    }

    try {
        $groups = ConvertTo-Array (Invoke-DocGraph -Path "/groups?`$select=id,groupTypes,mailEnabled,securityEnabled" -FollowNextLink $true)
    } catch {
        Write-Warning "Unable to collect group inventory summary."
    }

    try {
        $servicePrincipals = ConvertTo-Array (Invoke-DocGraph -Path "/servicePrincipals?`$select=id" -FollowNextLink $true)
    } catch {
        Write-Warning "Unable to collect service principal summary."
    }

    try {
        $applications = ConvertTo-Array (Invoke-DocGraph -Path "/applications?`$select=id" -FollowNextLink $true)
    } catch {
        Write-Warning "Unable to collect app registration summary."
    }

    try {
        $applicationsForCredentials = ConvertTo-Array (Invoke-DocGraph -Path "/applications?`$select=id,displayName,passwordCredentials,keyCredentials" -FollowNextLink $true)
        foreach($app in $applicationsForCredentials){
            $appName = if([string]::IsNullOrWhiteSpace("$($app.displayName)")){ "$($app.id)" } else { "$($app.displayName)" }
            $expiringForApp = 0

            $passwordCredentials = ConvertTo-Array $app.passwordCredentials
            foreach($credential in $passwordCredentials){
                $endDate = ConvertTo-DateTimeOrNull -Value $credential.endDateTime
                if($null -eq $endDate){
                    continue
                }

                $daysToExpiry = [Math]::Floor(($endDate.ToUniversalTime() - $nowUtc).TotalDays)
                if($daysToExpiry -lt 0){
                    $expiredCredentials++
                    continue
                }

                if($daysToExpiry -le $credentialExpiryThresholdDays){
                    $credentialsExpiringSoon++
                    $expiringForApp++
                }
            }

            $keyCredentials = ConvertTo-Array $app.keyCredentials
            foreach($credential in $keyCredentials){
                $endDate = ConvertTo-DateTimeOrNull -Value $credential.endDateTime
                if($null -eq $endDate){
                    continue
                }

                $daysToExpiry = [Math]::Floor(($endDate.ToUniversalTime() - $nowUtc).TotalDays)
                if($daysToExpiry -lt 0){
                    $expiredCredentials++
                    continue
                }

                if($daysToExpiry -le $credentialExpiryThresholdDays){
                    $credentialsExpiringSoon++
                    $expiringForApp++
                }
            }

            if($expiringForApp -gt 0){
                $appsWithExpiringCredentials[$appName] = $expiringForApp
            }
        }
    } catch {
        Write-Warning "Unable to collect app credential expiry findings."
    }

    try {
        $conditionalAccessPolicies = ConvertTo-Array (Invoke-DocGraph -Path "/identity/conditionalAccess/policies" -Beta -FollowNextLink $true)
    } catch {
        Write-Warning "Unable to collect conditional access summary."
    }

    try {
        $directoryRoles = ConvertTo-Array (Invoke-DocGraph -Path "/directoryRoles" -FollowNextLink $true)
        foreach($role in $directoryRoles){
            $members = ConvertTo-Array (Invoke-DocGraph -Path "/directoryRoles/$($role.id)/members?`$select=id" -FollowNextLink $true)
            $roleMemberSummary += [PSCustomObject]@{
                Role = $role.displayName
                MemberCount = $members.Count
            }
        }
    } catch {
        Write-Warning "Unable to collect directory role membership summary."
    }

    $enabledUsers = ($users | Where-Object { $_.accountEnabled -eq $true }).Count
    $disabledUsers = ($users | Where-Object { $_.accountEnabled -eq $false }).Count
    $guestUsers = ($users | Where-Object { "$($_.userType)" -match "Guest" }).Count
    $memberUsers = ($users | Where-Object { "$($_.userType)" -match "Member" }).Count

    $dynamicGroups = ($groups | Where-Object { $_.groupTypes -contains "DynamicMembership" }).Count
    $securityGroups = ($groups | Where-Object { $_.securityEnabled -eq $true -and $_.mailEnabled -eq $false }).Count
    $microsoft365Groups = ($groups | Where-Object { $_.mailEnabled -eq $true -and $_.groupTypes -contains "Unified" }).Count

    $caEnabled = 0
    $caDisabled = 0
    $caReportOnly = 0
    $caUnknown = 0
    foreach($policy in $conditionalAccessPolicies){
        switch(Get-PolicyStateGroup -State $policy.state){
            "Enabled" { $caEnabled++ }
            "Disabled" { $caDisabled++ }
            "ReportOnly" { $caReportOnly++ }
            Default { $caUnknown++ }
        }
    }

    $globalAdminRole = $roleMemberSummary | Where-Object { $_.Role -eq "Global Administrator" } | Select-Object -First 1
    $globalAdminCount = if($null -eq $globalAdminRole){ 0 } else { $globalAdminRole.MemberCount }

    $kpiSummary = [PSCustomObject]@{
        Tenant = if($null -eq $organization){ "Unknown" } else { $organization.displayName }
        TenantType = if($null -eq $organization){ "Unknown" } else { $organization.tenantType }
        TotalUsers = $users.Count
        EnabledUsers = $enabledUsers
        DisabledUsers = $disabledUsers
        MemberUsers = $memberUsers
        GuestUsers = $guestUsers
        TotalGroups = $groups.Count
        DynamicGroups = $dynamicGroups
        SecurityGroups = $securityGroups
        Microsoft365Groups = $microsoft365Groups
        AppRegistrations = $applications.Count
        ServicePrincipals = $servicePrincipals.Count
        ConditionalAccessPoliciesEnabled = $caEnabled
        ConditionalAccessPoliciesReportOnly = $caReportOnly
        ConditionalAccessPoliciesDisabled = $caDisabled
        ConditionalAccessPoliciesUnknown = $caUnknown
        DirectoryRoles = $directoryRoles.Count
        GlobalAdministrators = $globalAdminCount
        StaleGuestAccounts90Days = $staleGuestUsers
        CredentialsExpiring30Days = $credentialsExpiringSoon
        ExpiredCredentials = $expiredCredentials
    }

    $DocSec.Objects = $kpiSummary
    $DocSec.Transpose = $true

    $DocSecIdentity = New-Object DocSection
    $DocSecIdentity.Title = "Identity Inventory"
    $DocSecIdentity.Text = "Counts of key identity object types in Entra ID."
    $DocSecIdentity.Objects = @(
        [PSCustomObject]@{ Metric = "Users"; Count = $users.Count },
        [PSCustomObject]@{ Metric = "Enabled Users"; Count = $enabledUsers },
        [PSCustomObject]@{ Metric = "Disabled Users"; Count = $disabledUsers },
        [PSCustomObject]@{ Metric = "Member Users"; Count = $memberUsers },
        [PSCustomObject]@{ Metric = "Guest Users"; Count = $guestUsers },
        [PSCustomObject]@{ Metric = "Groups"; Count = $groups.Count },
        [PSCustomObject]@{ Metric = "Dynamic Groups"; Count = $dynamicGroups },
        [PSCustomObject]@{ Metric = "Security Groups"; Count = $securityGroups },
        [PSCustomObject]@{ Metric = "Microsoft 365 Groups"; Count = $microsoft365Groups },
        [PSCustomObject]@{ Metric = "App Registrations"; Count = $applications.Count },
        [PSCustomObject]@{ Metric = "Service Principals"; Count = $servicePrincipals.Count }
    )
    $DocSecIdentity.Transpose = $false

    $DocSecConditionalAccess = New-Object DocSection
    $DocSecConditionalAccess.Title = "Conditional Access Posture"
    $DocSecConditionalAccess.Text = "Count of Conditional Access policies by state."
    $DocSecConditionalAccess.Objects = @(
        [PSCustomObject]@{ State = "Enabled"; PolicyCount = $caEnabled },
        [PSCustomObject]@{ State = "ReportOnly"; PolicyCount = $caReportOnly },
        [PSCustomObject]@{ State = "Disabled"; PolicyCount = $caDisabled },
        [PSCustomObject]@{ State = "Unknown"; PolicyCount = $caUnknown }
    )
    $DocSecConditionalAccess.Transpose = $false

    $authMethodSummary = @()
    $authMethodDefinitions = @(
        @{ Name = "FIDO2"; Path = "/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/fido2" },
        @{ Name = "Microsoft Authenticator"; Path = "/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/microsoftAuthenticator" },
        @{ Name = "Temporary Access Pass"; Path = "/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/TemporaryAccessPass" },
        @{ Name = "Email OTP"; Path = "/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/email" },
        @{ Name = "SMS"; Path = "/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/sms" }
    )
    foreach($method in $authMethodDefinitions){
        try {
            $methodPolicy = Invoke-DocGraph -Path $method.Path -Beta
            $authMethodSummary += [PSCustomObject]@{
                Method = $method.Name
                State = Get-MethodPolicyState -MethodPolicy $methodPolicy
            }
        } catch {
            $authMethodSummary += [PSCustomObject]@{
                Method = $method.Name
                State = "Unavailable"
            }
        }
    }

    $DocSecAuthMethods = New-Object DocSection
    $DocSecAuthMethods.Title = "Authentication Methods Policy"
    $DocSecAuthMethods.Text = "Current policy state for key authentication methods."
    $DocSecAuthMethods.Objects = $authMethodSummary
    $DocSecAuthMethods.Transpose = $false

    $DocSecRoleAssignments = New-Object DocSection
    $DocSecRoleAssignments.Title = "Top Directory Roles by Members"
    $DocSecRoleAssignments.Text = "Top 10 activated directory roles by assigned member count."
    $DocSecRoleAssignments.Objects = $roleMemberSummary | Sort-Object MemberCount,Role -Descending | Select-Object -First 10
    if($null -eq $DocSecRoleAssignments.Objects -or $DocSecRoleAssignments.Objects.Count -eq 0){
        $DocSecRoleAssignments.Objects = @(
            [PSCustomObject]@{
                Role = "No data available"
                MemberCount = 0
            }
        )
    }
    $DocSecRoleAssignments.Transpose = $false

    $appsWithExpiringCredentialsTop = @()
    foreach($appName in $appsWithExpiringCredentials.Keys){
        $appsWithExpiringCredentialsTop += [PSCustomObject]@{
            Application = $appName
            ExpiringCredentials = $appsWithExpiringCredentials[$appName]
        }
    }
    $appsWithExpiringCredentialsTop = $appsWithExpiringCredentialsTop | Sort-Object ExpiringCredentials,Application -Descending | Select-Object -First 5

    $expiringAppsText = if($null -ne $appsWithExpiringCredentialsTop -and $appsWithExpiringCredentialsTop.Count -gt 0){
        ($appsWithExpiringCredentialsTop | ForEach-Object { "$($_.Application) ($($_.ExpiringCredentials))" }) -join ", "
    } else {
        "None"
    }

    $DocSecTopFindings = New-Object DocSection
    $DocSecTopFindings.Title = "Top Findings"
    $DocSecTopFindings.Text = "Compact risk findings for stale guest identities and application credential hygiene."
    $DocSecTopFindings.Objects = @(
        [PSCustomObject]@{
            Finding = "Stale guest accounts (>= 90 days)"
            Severity = if($staleGuestUsers -gt 0){ "Medium" } else { "Low" }
            Count = $staleGuestUsers
            Details = "Guest accounts with last sign-in older than 90 days or never signed in since creation."
        },
        [PSCustomObject]@{
            Finding = "Never-signed-in stale guest accounts (>= 90 days)"
            Severity = if($neverSignedInStaleGuests -gt 0){ "Medium" } else { "Low" }
            Count = $neverSignedInStaleGuests
            Details = "Subset of stale guests with no recorded sign-in activity."
        },
        [PSCustomObject]@{
            Finding = "Credentials expiring in <= 30 days"
            Severity = if($credentialsExpiringSoon -gt 0){ "High" } else { "Low" }
            Count = $credentialsExpiringSoon
            Details = "Top apps: $expiringAppsText"
        },
        [PSCustomObject]@{
            Finding = "Expired application credentials"
            Severity = if($expiredCredentials -gt 0){ "High" } else { "Low" }
            Count = $expiredCredentials
            Details = "Application secrets/certificates already past end date."
        }
    )
    $DocSecTopFindings.Transpose = $false

    $DocSec.SubSections += @(
        $DocSecIdentity,
        $DocSecConditionalAccess,
        $DocSecAuthMethods,
        $DocSecRoleAssignments,
        $DocSecTopFindings
    )

    return $DocSec
}
