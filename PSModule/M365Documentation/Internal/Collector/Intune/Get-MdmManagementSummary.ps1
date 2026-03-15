Function Get-MdmManagementSummary(){
    <#
    .SYNOPSIS
    This function provides a management summary of Intune operational metrics.
    .DESCRIPTION
    The function collects summary counters for managed device OS distribution, application count,
    and failed deployments in the last 30 days.
    .EXAMPLE
    Get-MdmManagementSummary
    Returns an Intune management summary section.
    .NOTES
    NAME: Get-MdmManagementSummary
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

    function Get-RecordDate {
        param([object]$Record)

        $dateProperties = @(
            "lastReportedDateTime",
            "lastStateUpdateDateTime",
            "occurrenceDateTime",
            "createdDateTime",
            "lastModifiedDateTime"
        )

        foreach($property in $dateProperties){
            if($Record.PSObject.Properties.Name -contains $property -and $null -ne $Record.$property){
                try {
                    return [datetime]$Record.$property
                } catch {
                    continue
                }
            }
        }

        return $null
    }

    function Test-IsFailureRecord {
        param([object]$Record)

        $failureWords = "fail|failed|error|noncompliant|remediationfailed"
        $nonFailureWords = "success|succeeded|compliant|notapplicable"

        $statusProperties = @(
            "status",
            "complianceStatus",
            "deploymentStatus",
            "installState",
            "runState",
            "detectionState",
            "preRemediationDetectionScriptOutput",
            "postRemediationDetectionScriptOutput"
        )

        foreach($property in $statusProperties){
            if($Record.PSObject.Properties.Name -contains $property -and $null -ne $Record.$property){
                $statusValue = "$($Record.$property)".ToLowerInvariant()
                if($statusValue -match $failureWords -and $statusValue -notmatch $nonFailureWords){
                    return $true
                }
            }
        }

        if($Record.PSObject.Properties.Name -contains "errorCode"){
            try {
                if([int]$Record.errorCode -gt 0){
                    return $true
                }
            } catch {}
        }

        return $false
    }

    function Get-FailureCountInWindow {
        param(
            [object[]]$Records,
            [datetime]$WindowStart
        )

        $count = 0
        foreach($record in $Records){
            $recordDate = Get-RecordDate -Record $record
            if($null -eq $recordDate -or $recordDate -lt $WindowStart){
                continue
            }

            if(Test-IsFailureRecord -Record $record){
                $count++
            }
        }

        return $count
    }

    function Get-OperatingSystemFamily {
        param([string]$OperatingSystem)

        if([string]::IsNullOrWhiteSpace($OperatingSystem)){
            return "Unknown"
        }

        $os = $OperatingSystem.ToLowerInvariant()

        if($os -match "windows"){
            return "Windows"
        }

        if($os -match "ios|ipados"){
            return "iOS/iPadOS"
        }

        if($os -match "android"){
            return "Android"
        }

        if($os -match "mac|osx"){
            return "macOS"
        }

        return "Other"
    }

    function Get-RecordLabel {
        param(
            [object]$Record,
            [string[]]$PropertyNames,
            [string]$Fallback = "Unknown"
        )

        foreach($propertyName in $PropertyNames){
            if($Record.PSObject.Properties.Name -contains $propertyName -and -not [string]::IsNullOrWhiteSpace("$($Record.$propertyName)")){
                return "$($Record.$propertyName)"
            }
        }

        return $Fallback
    }

    function Add-Counter {
        param(
            [hashtable]$Counter,
            [string]$Key,
            [int]$Value = 1
        )

        if([string]::IsNullOrWhiteSpace($Key)){
            $Key = "Unknown"
        }

        if($Counter.ContainsKey($Key)){
            $Counter[$Key] += $Value
        } else {
            $Counter[$Key] = $Value
        }
    }

    function Get-TopCounterItems {
        param(
            [hashtable]$Counter,
            [string]$NameProperty,
            [string]$CountProperty,
            [int]$Top = 10
        )

        $items = @()
        foreach($key in $Counter.Keys){
            $items += [PSCustomObject]@{
                $NameProperty = $key
                $CountProperty = $Counter[$key]
            }
        }

        return $items | Sort-Object -Property $CountProperty, $NameProperty -Descending | Select-Object -First $Top
    }

    function Get-CompliancePosture {
        param([string]$ComplianceState)

        if([string]::IsNullOrWhiteSpace($ComplianceState)){
            return "Unknown"
        }

        $state = $ComplianceState.ToLowerInvariant()

        if($state -eq "compliant"){
            return "Compliant"
        }

        if($state -eq "noncompliant"){
            return "NonCompliant"
        }

        if($state -eq "ingraceperiod"){
            return "InGracePeriod"
        }

        if($state -eq "configmanager"){
            return "ConfigManager"
        }

        if($state -eq "error"){
            return "Error"
        }

        return $ComplianceState
    }

    function Get-StaleBucket {
        param(
            [datetime]$SyncDate,
            [datetime]$NowDate
        )

        if($null -eq $SyncDate){
            return "Unknown"
        }

        $ageInDays = [Math]::Floor(($NowDate.ToUniversalTime() - $SyncDate.ToUniversalTime()).TotalDays)
        if($ageInDays -lt 0){
            $ageInDays = 0
        }

        if($ageInDays -le 7){
            return "0-7 days"
        }

        if($ageInDays -le 30){
            return "8-30 days"
        }

        if($ageInDays -le 60){
            return "31-60 days"
        }

        return "61+ days"
    }

    $DocSec = New-Object DocSection
    $DocSec.Title = "Management Summary"
    $DocSec.Text = "This section contains an Intune management summary with device, compliance, app, and failed deployment metrics for the last 30 days."
    $DocSec.SubSections = @()

    $windowStart = (Get-Date).AddDays(-30)
    $now = Get-Date

    $managedDevices = @()
    $mobileApps = @()
    $failedAppDeployments = 0
    $failedConfigurationDeployments = 0
    $failedComplianceDeployments = 0
    $failedScriptDeployments = 0
    $appFailureCounter = @{}
    $configurationFailureByPolicy = @{}
    $complianceFailureByPolicy = @{}

    try {
        $managedDevices = ConvertTo-Array (Invoke-DocGraph -Path "/deviceManagement/managedDevices" -Beta -FollowNextLink $true)
    } catch {
        Write-Warning "Unable to collect managed devices summary."
    }

    try {
        $mobileApps = ConvertTo-Array (Invoke-DocGraph -Path "/deviceAppManagement/mobileApps" -Beta -FollowNextLink $true)
    } catch {
        Write-Warning "Unable to collect mobile application summary."
    }

    try {
        $appTroubleshootingEvents = ConvertTo-Array (Invoke-DocGraph -Path "/deviceAppManagement/mobileAppTroubleshootingEvents" -Beta -FollowNextLink $true)
        $failedAppDeployments = Get-FailureCountInWindow -Records $appTroubleshootingEvents -WindowStart $windowStart

        foreach($event in $appTroubleshootingEvents){
            $recordDate = Get-RecordDate -Record $event
            if($null -eq $recordDate -or $recordDate -lt $windowStart){
                continue
            }

            if(-not (Test-IsFailureRecord -Record $event)){
                continue
            }

            $appLabel = Get-RecordLabel -Record $event -PropertyNames @("appDisplayName", "applicationName", "mobileAppDisplayName", "appName", "displayName")
            if($appLabel -eq "Unknown"){
                $appLabel = Get-RecordLabel -Record $event -PropertyNames @("appId", "mobileAppId", "applicationId")
            }

            Add-Counter -Counter $appFailureCounter -Key $appLabel
        }
    } catch {
        Write-Warning "Unable to collect app deployment failure summary."
    }

    try {
        $configurationPolicies = ConvertTo-Array (Invoke-DocGraph -Path "/deviceManagement/deviceConfigurations" -Beta)
        foreach($policy in $configurationPolicies){
            $deviceStatuses = ConvertTo-Array (Invoke-DocGraph -Path "/deviceManagement/deviceConfigurations/$($policy.id)/deviceStatuses" -Beta -FollowNextLink $true)
            $currentFailureCount = Get-FailureCountInWindow -Records $deviceStatuses -WindowStart $windowStart
            $failedConfigurationDeployments += $currentFailureCount

            if($currentFailureCount -gt 0){
                $policyLabel = if([string]::IsNullOrWhiteSpace($policy.displayName)){ "$($policy.id)" } else { "$($policy.displayName)" }
                Add-Counter -Counter $configurationFailureByPolicy -Key $policyLabel -Value $currentFailureCount
            }
        }
    } catch {
        Write-Warning "Unable to collect configuration deployment failure summary."
    }

    try {
        $compliancePolicies = ConvertTo-Array (Invoke-DocGraph -Path "/deviceManagement/deviceCompliancePolicies" -Beta)
        foreach($policy in $compliancePolicies){
            $deviceStatuses = ConvertTo-Array (Invoke-DocGraph -Path "/deviceManagement/deviceCompliancePolicies/$($policy.id)/deviceStatuses" -Beta -FollowNextLink $true)
            $currentFailureCount = Get-FailureCountInWindow -Records $deviceStatuses -WindowStart $windowStart
            $failedComplianceDeployments += $currentFailureCount

            if($currentFailureCount -gt 0){
                $policyLabel = if([string]::IsNullOrWhiteSpace($policy.displayName)){ "$($policy.id)" } else { "$($policy.displayName)" }
                Add-Counter -Counter $complianceFailureByPolicy -Key $policyLabel -Value $currentFailureCount
            }
        }
    } catch {
        Write-Warning "Unable to collect compliance deployment failure summary."
    }

    try {
        $scriptPathDefinitions = @(
            @{ List = "/deviceManagement/deviceManagementScripts"; States = "/deviceManagement/deviceManagementScripts/{0}/deviceRunStates" },
            @{ List = "/deviceManagement/deviceShellScripts"; States = "/deviceManagement/deviceShellScripts/{0}/deviceRunStates" },
            @{ List = "/deviceManagement/deviceHealthScripts"; States = "/deviceManagement/deviceHealthScripts/{0}/deviceRunStates" },
            @{ List = "/deviceManagement/deviceComplianceScripts"; States = "/deviceManagement/deviceComplianceScripts/{0}/deviceRunStates" }
        )

        foreach($pathDefinition in $scriptPathDefinitions){
            $scripts = ConvertTo-Array (Invoke-DocGraph -Path $pathDefinition.List -Beta)
            foreach($script in $scripts){
                if($null -eq $script.id){
                    continue
                }

                $statePath = [string]::Format($pathDefinition.States, $script.id)
                $runStates = ConvertTo-Array (Invoke-DocGraph -Path $statePath -Beta -FollowNextLink $true)
                $failedScriptDeployments += Get-FailureCountInWindow -Records $runStates -WindowStart $windowStart
            }
        }
    } catch {
        Write-Warning "Unable to collect script deployment failure summary."
    }

    $osCounter = @{}
    foreach($device in $managedDevices){
        $family = Get-OperatingSystemFamily -OperatingSystem $device.operatingSystem
        if($osCounter.ContainsKey($family)){
            $osCounter[$family] += 1
        } else {
            $osCounter[$family] = 1
        }
    }

    $osSummary = @()
    foreach($family in $osCounter.Keys){
        $osSummary += [PSCustomObject]@{
            OperatingSystem = $family
            DeviceCount = $osCounter[$family]
        }
    }

    $complianceCounter = @{}
    $staleDeviceBuckets = @{
        "0-7 days" = 0
        "8-30 days" = 0
        "31-60 days" = 0
        "61+ days" = 0
        "Unknown" = 0
    }
    foreach($device in $managedDevices){
        $compliancePosture = Get-CompliancePosture -ComplianceState $device.complianceState
        Add-Counter -Counter $complianceCounter -Key $compliancePosture

        $syncDate = $null
        if($device.PSObject.Properties.Name -contains "lastSyncDateTime" -and $null -ne $device.lastSyncDateTime){
            try {
                $syncDate = [datetime]$device.lastSyncDateTime
            } catch {
                $syncDate = $null
            }
        }

        $staleBucket = Get-StaleBucket -SyncDate $syncDate -NowDate $now
        $staleDeviceBuckets[$staleBucket] += 1
    }

    $complianceSummary = @()
    foreach($posture in $complianceCounter.Keys){
        $complianceSummary += [PSCustomObject]@{
            ComplianceState = $posture
            DeviceCount = $complianceCounter[$posture]
        }
    }

    $staleSummary = @(
        [PSCustomObject]@{ CheckInAge = "0-7 days"; DeviceCount = $staleDeviceBuckets["0-7 days"] },
        [PSCustomObject]@{ CheckInAge = "8-30 days"; DeviceCount = $staleDeviceBuckets["8-30 days"] },
        [PSCustomObject]@{ CheckInAge = "31-60 days"; DeviceCount = $staleDeviceBuckets["31-60 days"] },
        [PSCustomObject]@{ CheckInAge = "61+ days"; DeviceCount = $staleDeviceBuckets["61+ days"] },
        [PSCustomObject]@{ CheckInAge = "Unknown"; DeviceCount = $staleDeviceBuckets["Unknown"] }
    )

    $topFailingApps = Get-TopCounterItems -Counter $appFailureCounter -NameProperty "Application" -CountProperty "FailedDeployments" -Top 10

    $combinedProfileCounter = @{}
    foreach($profileName in $configurationFailureByPolicy.Keys){
        Add-Counter -Counter $combinedProfileCounter -Key ("Configuration: " + $profileName) -Value $configurationFailureByPolicy[$profileName]
    }
    foreach($profileName in $complianceFailureByPolicy.Keys){
        Add-Counter -Counter $combinedProfileCounter -Key ("Compliance: " + $profileName) -Value $complianceFailureByPolicy[$profileName]
    }
    $topFailingProfiles = Get-TopCounterItems -Counter $combinedProfileCounter -NameProperty "Profile" -CountProperty "FailedDeployments" -Top 10

    if($null -eq $topFailingApps -or $topFailingApps.Count -eq 0){
        $topFailingApps = @(
            [PSCustomObject]@{
                Application = "No data available"
                FailedDeployments = 0
            }
        )
    }

    if($null -eq $topFailingProfiles -or $topFailingProfiles.Count -eq 0){
        $topFailingProfiles = @(
            [PSCustomObject]@{
                Profile = "No data available"
                FailedDeployments = 0
            }
        )
    }

    $kpiSummary = [PSCustomObject]@{
        WindowStartUtc = $windowStart.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        WindowEndUtc = $now.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        ManagedDeviceCount = $managedDevices.Count
        ApplicationCount = $mobileApps.Count
        FailedAppDeployments = $failedAppDeployments
        FailedConfigurationDeployments = $failedConfigurationDeployments
        FailedComplianceDeployments = $failedComplianceDeployments
        FailedScriptDeployments = $failedScriptDeployments
        TotalFailedDeployments = ($failedAppDeployments + $failedConfigurationDeployments + $failedComplianceDeployments + $failedScriptDeployments)
        StaleDevices31DaysOrMore = ($staleDeviceBuckets["31-60 days"] + $staleDeviceBuckets["61+ days"])
    }

    $DocSec.Objects = $kpiSummary
    $DocSec.Transpose = $true

    $DocSecOperatingSystem = New-Object DocSection
    $DocSecOperatingSystem.Title = "Managed Devices by Operating System"
    $DocSecOperatingSystem.Text = "Count of managed devices grouped by operating system family."
    $DocSecOperatingSystem.Objects = $osSummary | Sort-Object OperatingSystem
    $DocSecOperatingSystem.Transpose = $false

    $DocSecStaleDevices = New-Object DocSection
    $DocSecStaleDevices.Title = "Stale Device Distribution"
    $DocSecStaleDevices.Text = "Count of managed devices by last check-in age bucket."
    $DocSecStaleDevices.Objects = $staleSummary
    $DocSecStaleDevices.Transpose = $false

    $DocSecCompliancePosture = New-Object DocSection
    $DocSecCompliancePosture.Title = "Compliance Posture"
    $DocSecCompliancePosture.Text = "Count of managed devices by compliance state."
    $DocSecCompliancePosture.Objects = $complianceSummary | Sort-Object ComplianceState
    $DocSecCompliancePosture.Transpose = $false

    $DocSecFailure = New-Object DocSection
    $DocSecFailure.Title = "Failed Deployments (Last 30 Days)"
    $DocSecFailure.Text = "Counts of failed deployments by workload in the last 30 days."
    $DocSecFailure.Objects = @(
        [PSCustomObject]@{ Workload = "Applications"; FailedDeployments = $failedAppDeployments },
        [PSCustomObject]@{ Workload = "Configuration Policies"; FailedDeployments = $failedConfigurationDeployments },
        [PSCustomObject]@{ Workload = "Compliance Policies"; FailedDeployments = $failedComplianceDeployments },
        [PSCustomObject]@{ Workload = "Scripts"; FailedDeployments = $failedScriptDeployments }
    )
    $DocSecFailure.Transpose = $false

    $DocSecTopFailingApps = New-Object DocSection
    $DocSecTopFailingApps.Title = "Top Failing Applications (Last 30 Days)"
    $DocSecTopFailingApps.Text = "Top 10 applications by failed deployment events in the last 30 days."
    $DocSecTopFailingApps.Objects = $topFailingApps
    $DocSecTopFailingApps.Transpose = $false

    $DocSecTopFailingProfiles = New-Object DocSection
    $DocSecTopFailingProfiles.Title = "Top Failing Profiles (Last 30 Days)"
    $DocSecTopFailingProfiles.Text = "Top 10 configuration/compliance profiles by failed deployment events in the last 30 days."
    $DocSecTopFailingProfiles.Objects = $topFailingProfiles
    $DocSecTopFailingProfiles.Transpose = $false

    $DocSec.SubSections += @(
        $DocSecOperatingSystem,
        $DocSecStaleDevices,
        $DocSecCompliancePosture,
        $DocSecFailure,
        $DocSecTopFailingApps,
        $DocSecTopFailingProfiles
    )

    return $DocSec
}
