$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
Import-Module "$scriptPath\M365Documentation\M365Documentation.psd1" -Force -ErrorAction Stop

New-M365DocAppRegistration -displayName "WPNinjasTest2"  