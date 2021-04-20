# Advanced Usage

This section covers advanced scenarios of the documentation solution.

## Custom App registration for silent execution


## Output to Json

Outputing the documentation to JSON allows you to reimport the documentation at a later time and recreate a word file or to compare the json files between multiple dates.

```powershell

Connect-M365Doc
$doc = Get-M365Doc -Components Intune -ExcludeSections "MobileAppDetailed"

# JSON export
$doc | Write-M365DocJson -FullDocumentationPath "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc.json"


```

## Output to CSV

Outputing the data to CSV files, one per Section can be used if you document for example Conditional Access.

```powershell

Connect-M365Doc
$doc = Get-M365Doc -Components Intune -ExcludeSections "MobileAppDetailed"

# JSON export
$doc | Write-M365DocCSV -FullDocumentationPath "c:\temp\"

```

## Import Json File

You can import a previous exported JSON file. This can be useful if you want to recreate the documentation offline without collecting all information again.

```powershell

# Import existing configuration
$bkp = Get-M365Doc -BackupFile "c:\temp\20210503-WPNinjas-Doc.json"

# Create word file from Json file
$bkp | Write-M365DocWord -FullDocumentationPath "c:\temp\$($bkp.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-DocBkp.docx"


```

## Optimize and Translate Object names and values

The documented names are normally the API names of the properties. Sometimes it's helpful to be able to document the correct name from the UI. For this we precreated many translation files which automatically does this job for you. You can even extend that for the objects which we haven't done this yet.

```powershell

Connect-M365Doc
$doc = Get-M365Doc -Components Intune -ExcludeSections "MobileAppDetailed"

# Optimize content including translation
$docnew = $doc | Optimize-M365Doc -UseTranslationFiles 

# Create Word file
$docnew | Write-M365DocWord -FullDocumentationPath "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc-Translated.docx"

```

Other options of the Optimize-M365Doc command are:

- *UseTranslationFiles:* If available the function will translate property names with the name in the UI. W
Note:
These Translations need to be created manually, only a few are translated yet. If you are willing
to support this project. You can do this by [translating the json files](https://github.com/ThomasKur/M365Documentation/blob/master/AddTranslation.md) which are mentioned to you when you generate the documentation in your tenant.

- *UseCamelCase:* If no tranlsation is available for a property or the -UseTranslationFiles switch was not used, then property names are beautified based on Caml case standard.

- *MaxStringLengthSettings:* Values with texts longer than the amount of characters specified by this property then they are trimmed.

- *ExcludeEmptyValues:* Properties with empty values are removed from the output.

- *ExcludeProperties:* Properties with these names are skipped and remove from the output. This can be helpful to remove for example the id or created by property.
