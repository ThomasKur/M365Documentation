#Requires -Modules Pester

# Invoke-DocGraph used to return the caught ErrorRecord on 403/401. Collectors stored it as
# section data, and Write-M365DocJson then serialized its exception and assembly metadata.

BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    $modulePath = Join-Path (Split-Path -Parent $here) 'M365Documentation'
    . (Join-Path $modulePath 'Internal/Helper/Invoke-DocGraph.ps1')

    function Test-TokenExpiration { }
    $script:token = [PSCustomObject]@{ AccessToken = 'stub' }

    function New-HttpError {
        param([System.Net.HttpStatusCode]$StatusCode)
        $response = [System.Net.Http.HttpResponseMessage]::new($StatusCode)
        [Microsoft.PowerShell.Commands.HttpResponseException]::new("HTTP $([int]$StatusCode)", $response)
    }
}

Describe 'Invoke-DocGraph error handling' {

    It 'returns nothing on <Code> so no error object reaches the documentation' -ForEach @(
        @{ Code = 'Forbidden' }
        @{ Code = 'Unauthorized' }
    ) {
        $err = New-HttpError -StatusCode $Code
        Mock Invoke-RestMethod { throw $err }
        $result = Invoke-DocGraph -Path '/print/printers' -WarningAction SilentlyContinue
        $result | Should -BeNullOrEmpty
    }

    It 'still warns on Forbidden' {
        $err = New-HttpError -StatusCode Forbidden
        Mock Invoke-RestMethod { throw $err }
        Invoke-DocGraph -Path '/print/printers' -WarningVariable warnings -WarningAction SilentlyContinue | Out-Null
        $warnings | Should -Match 'Forbidden'
    }

    It 'returns a Not Found marker on NotFound (unchanged upstream behavior)' {
        $err = New-HttpError -StatusCode NotFound
        Mock Invoke-RestMethod { throw $err }
        $result = Invoke-DocGraph -Path '/organization/x/branding' -WarningAction SilentlyContinue
        $result.Status | Should -Be 'Not Found'
    }

    It 'returns the response on success' {
        Mock Invoke-RestMethod { [PSCustomObject]@{ value = @([PSCustomObject]@{ id = '1' }) } }
        (Invoke-DocGraph -Path '/print/printers').value.id | Should -Be '1'
    }
}
