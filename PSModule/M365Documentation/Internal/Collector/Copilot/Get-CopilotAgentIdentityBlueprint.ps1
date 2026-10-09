function Get-CopilotAgentIdentityBlueprint(){
    <#
    .SYNOPSIS
    Gets Microsoft Entra agent identity blueprints and their communication configuration.
    .DESCRIPTION
    Retrieves agent identity blueprints from Microsoft Graph beta and adds the communication
    configuration for each blueprint to its corresponding object.
    .EXAMPLE
    Get-CopilotAgentIdentityBlueprint
    Returns agent identity blueprints and their communication configurations.
    .NOTES
    NAME: Get-CopilotAgentIdentityBlueprint
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $blueprints = (Invoke-DocGraph -Path "/applications/microsoft.graph.agentIdentityBlueprint" -Beta).Value
    if($null -eq $blueprints){
        return $null
    }

    $DocSec = New-Object DocSection
    $DocSec.Title = "Agent Identity Blueprints"
    $DocSec.Text = "Lists Microsoft Entra agent identity blueprints, including each blueprint's communication configuration. Requires AgentIdentityBlueprint.Read.All and AgentCommunicationConfiguration.ReadWrite.All permissions. These Microsoft Graph beta APIs are subject to change and are not supported for production use."
    $DocSec.Objects = @()
    $DocSec.Transpose = $false

    foreach($blueprint in $blueprints){
        if([string]::IsNullOrWhiteSpace($blueprint.id)){
            Write-Warning -Message "Copilot: Skipping communication configuration for an agent identity blueprint without an id."
            $DocSec.Objects += $blueprint
            continue
        }

        $communicationConfiguration = Invoke-DocGraph -Path "/applications/$($blueprint.id)/microsoft.graph.agentIdentityBlueprint/communicationConfiguration" -Beta
        $blueprint | Add-Member -MemberType NoteProperty -Name "communicationConfiguration" -Value $communicationConfiguration -Force
        $DocSec.Objects += $blueprint
    }

    if($DocSec.Objects.Count -eq 0){
        return $null
    }

    return $DocSec
}
