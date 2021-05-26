$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
import-module "$scriptPath\M365Documentation\M365Documentation.psm1" -force 
Connect-M365Doc
$doc = Get-M365Doc -Components Intune

#$doc | Write-M365DocWord -FullDocumentationPath "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc.docx"
#$doc | Write-M365DocJson -FullDocumentationPath "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc.json"

$docnew = $doc | Optimize-M365Doc -UseTranslationFiles -UseCamelCase -ExcludeProperties @("id","@odata.type") -ExcludeValues
$docnew | Write-M365DocWord -FullDocumentationPath "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc-Translated.docx"


#$bkp = Get-M365Doc -BackupFile "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc.json"
#$bkp | Write-M365DocWord -FullDocumentationPath "c:\temp\$($bkp.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-DocBkp.docx"


Write-Host "Created Documentation"