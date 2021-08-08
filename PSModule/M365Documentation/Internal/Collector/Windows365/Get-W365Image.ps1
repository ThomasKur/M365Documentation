Function Get-W365Image(){
    <#
    .SYNOPSIS
    This function is used to get the Windows 365 Images from the Beta Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets the Images
    .EXAMPLE
    Get-W365Image
    Returns the Images defined in Windows 365.
    .NOTES
    NAME: Get-W365Image
    #>
    [OutputType('DocSection')]
    [cmdletbinding()]
    param()

    $DocSec = New-Object DocSection

    $DocSec.Title = "Device Images"
    $DocSec.Text = "Lists all image resources associated with the tenant."
    $DocSec.Objects = (Invoke-DocGraph -Path "/deviceManagement/virtualEndpoint/deviceImages" -Beta).Value
    $DocSec.Transpose = $false
    if($null -eq $DocSec.Objects){
        return $null
    } else {
        return $DocSec
    }
    
}