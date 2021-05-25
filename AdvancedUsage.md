# Advanced Usage

This section covers advanced scenarios of the documentation solution.

## Connect to your tenant

### Connect with interactive authentication (Supports MFA)

The simplest way to connect is by using the following command which will prompt you to enter your credentials in the well known Microsoft dialogs.

```powershell

Connect-M365Doc

```

### Silent execution (Custom App registration)

Per default the module will use an app registration hosted in my tenant, which is completely free to use. But sometimes companies have restrictions and would like to create their own app registrations, especially when the documentation should be generated silently.

You can create the app registration on your own with these permission. If you can't grant specific permissions, then the documentation module will still work but the part which requires the permission will not be documented.

Current list of scopes:
"AccessReview.Read.All","Agreement.Read.All","AppCatalog.Read.All","Application.Read.All","CloudPC.Read.All","ConsentRequest.Read.All","Device.Read.All","DeviceManagementApps.Read.All","DeviceManagementConfiguration.Read.All","DeviceManagementManagedDevices.Read.All","DeviceManagementRBAC.Read.All","DeviceManagementServiceConfig.Read.All","Directory.Read.All","Domain.Read.All","Organization.Read.All","Policy.Read.All","Policy.ReadWrite.AuthenticationMethod","Policy.ReadWrite.FeatureRollout","PrintConnector.Read.All","Printer.Read.All","PrinterShare.Read.All","PrintSettings.Read.All","PrivilegedAccess.Read.AzureAD","PrivilegedAccess.Read.AzureADGroup","PrivilegedAccess.Read.AzureResources","User.Read"

```powershell

$p = New-M365DocAppRegistration
$p | fl

ClientID               : d5cf6364-82f7-4024-9ac1-73a9fd2a6ec3
ClientSecret           : S02AESdMlhLQIPYYw/cYtLkHkQS0H49jXh02AS6Ek0U=
ClientSecretExpiration : 21.07.2023 21:39:02
TenantId               : d873f16a-73a2-4ccf-9d36-67b8243ab99a


```

After the successfull creation of an app registration in AzureAD you can use the following command to connect:

```powershell

Connect-M365Doc -ClientId '00000000-0000-0000-0000-000000000000' -ClientSecret (ConvertTo-SecureString 'SuperSecretString' -AsPlainText -Force) -TenantId '00000000-0000-0000-0000-000000000000'

```

### Others

The Connect-M365Doc command is built around the MSAL.PS (Get-MsalToken) module which allows to use any authentication methods Azure AD supports. Because of that it is possible to provide just an authentication token which should be used by the module:

```powershell

[Microsoft.Identity.Client.AuthenticationResult]$yourtoken = Get-MsalToken

Connect-M365Doc -token $yourtoken

```

## Data Collection

### Online Collection

The default case to create a documentation is collecting all information directly from Microsoft Graph. This can be done viua the following commands:

```powershell

Connect-M365Doc
$doc = Get-M365Doc -Components Intune -ExcludeSections "MobileAppDetailed"

```

It's important to know that this command can take some minutes and I suggest collecting only the data you really need. Therefore the command supports selecting the Component (AzureAD, Intune, ...) and withtin these components selecting just a few sections. For example I exclude (-ExcludeSections) normally the MobileAppDetailed section because this one takes a lot of time and is in most cases not required. But you can also just collect specific sections with the -IncludeSections parameter.

### Import Json File

You can import a previous exported JSON file. This can be useful if you want to recreate the documentation offline without collecting all information again. In this example you can see that it is not required to execute the Conmnect-M365Doc.

```powershell

# Import existing configuration
$bkp = Get-M365Doc -BackupFile "c:\temp\20210503-WPNinjas-Doc.json"

# Create word file from Json file
$bkp | Write-M365DocWord -FullDocumentationPath "c:\temp\$($bkp.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-DocBkp.docx"


```

## Output

### Output to Json

Outputing the documentation to JSON allows you to reimport the documentation at a later time and recreate a word file or to compare the json files between multiple dates.

```powershell

Connect-M365Doc
$doc = Get-M365Doc -Components Intune -ExcludeSections "MobileAppDetailed"

# JSON export
$doc | Write-M365DocJson -FullDocumentationPath "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc.json"


```

### Output to CSV

Outputing the data to CSV files, one per Section can be used if you document for example Conditional Access.

```powershell

Connect-M365Doc
$doc = Get-M365Doc -Components Intune -ExcludeSections "MobileAppDetailed"

# JSON export
$doc | Write-M365DocCSV -FullDocumentationPath "c:\temp\"

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


