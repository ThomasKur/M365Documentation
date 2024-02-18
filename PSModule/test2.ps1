$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
import-module "$scriptPath\M365Documentation\M365Documentation.psm1" -force 

New-M365DocAppRegistration -displayName "WPNinjasTest2"  