# Advanced Usage

This section covers advanced scenarios of the documentation solution.

## Custom App registration for silent execution

Per default the module will use an app registration hosted in my tenant, which is completely free to use. But sometimes companies have restrictions and would like to create their own app registrations, especially when the documentation should be generated silently.

You can create the app registration on your own with these permission. If you can't grant specific permissions, then the documentation module will still work but the part which requires the permission will not be documented.

Current list of scopes:
"AccessReview.Read.All","Agreement.Read.All","AppCatalog.Read.All","Application.Read.All","CloudPC.Read.All","ConsentRequest.Read.All","Device.Read.All","DeviceManagementApps.Read.All","DeviceManagementConfiguration.Read.All","DeviceManagementManagedDevices.Read.All","DeviceManagementRBAC.Read.All","DeviceManagementServiceConfig.Read.All","Directory.Read.All","Domain.Read.All","Organization.Read.All","Policy.Read.All","Policy.ReadWrite.AuthenticationMethod","Policy.ReadWrite.FeatureRollout","PrintConnector.Read.All","Printer.Read.All","PrinterShare.Read.All","PrintSettings.Read.All","PrivilegedAccess.Read.AzureAD","PrivilegedAccess.Read.AzureADGroup","PrivilegedAccess.Read.AzureResources","User.Read"

```powershell

$p = New-M365DocAppRegistration
$p | fl

ClientID               : d5cf6364-82f7-4024-9ac1-73a9fd2a6ec3
ClientSecret           : S03AESdMlhLQIPYYw/cYtLkGkQS0H49jXh02AS6Ek0U=
ClientSecretExpiration : 21.07.2025 21:39:02
TenantId               : d873f16a-73a2-4ccf-9d36-67b8243ab99a


```

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

- *UseTranslationFiles:* If available the function will translate property names with the name in the UI.
Note:
These Translations need to be created manually, only a few are translated yet. If you are willing
to support this project. You can do this with the help of Invoke-M365DocTranslationUI.

- *UseCamelCase:* If no tranlsation is available for a property or the -UseTranslationFiles switch was not used, then property names are beautified based on Caml case standard.

- *MaxStringLengthSettings:* Values with texts longer than the amount of characters specified by this property then they are trimmed.

- *ExcludeEmptyValues:* Properties with empty values are removed from the output.

- *ExcludeProperties:* Properties with these names are skipped and remove from the output. This can be helpful to remove for example the id or created by property.
