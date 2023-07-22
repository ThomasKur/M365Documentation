$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
import-module "$scriptPath\M365Documentation\M365Documentation.psm1" -force 
Connect-M365Doc
$doc = Get-M365Doc -Components Intune -ExcludeSections @("MobileAppDetailed")

$doc | Write-M365DocWord -FullDocumentationPath "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc.docx"
$doc | Write-M365DocJson -FullDocumentationPath "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc.json"
$doc | Write-M365DocMd -FullDocumentationPath "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc.md"

$docnew = $doc | Optimize-M365Doc -UseTranslationFiles -UseCamelCase -ExcludeProperties @("id","@odata.type") 
$docnew | Write-M365DocWord -FullDocumentationPath "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc-Translated.docx"
$docnew | Write-M365DocMd -FullDocumentationPath "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc-Translated.md"

#$bkp = Get-M365Doc -BackupFile "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc.json"
#$bkp | Write-M365DocWord -FullDocumentationPath "c:\temp\$($bkp.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-DocBkp.docx"

#$bkp = Get-M365Doc -BackupFile "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc.json"
#$docnew = $bkp | Optimize-M365Doc -UseTranslationFiles -UseCamelCase -ExcludeProperties @("id","@odata.type") 
#$docnew | Write-M365DocWord -FullDocumentationPath "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc-Translated.docx"
Write-Host "Created Documentation"

