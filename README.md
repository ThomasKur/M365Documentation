# Automatic Microsoft 365 Documentation

<img align="right" src="https://github.com/ThomasKur/M365Documentation/raw/main/Logo/M365DocumentationLogo.png" width="300px" alt="Automatic M365 Documentation Logo">Automatic Microsoft 365 Documentation to simplify the life of admins and consultants. You can automatically document systems like:

- Microsoft Intune
- Microsoft Entra ID (Azure AD)
- Microsoft Cloud Print
- Microsoft Information protection
- Windows 365 (CloudPC)

_This list will expand in the near future._

This is the successor to the IntuneDocumentation module and has much more options like:

- Output to Json
  - Backup your configuration and create documentation later
  - Compare your configuration over time for example with <http://www.jsondiff.com/>
- Output to CSV
- Output to Markdown/MD
- Output to HTML
- Flexible Authentication with MSAL.PS
  - Support for Certificate and Secret based Authentication

Through the new architecture much other features will follow in the near future.

## Usage

### Installation

The required modules are fully available in the PowerShell Gallery and therefore simple to install.

```powershell

Install-Module MSAL.PS
Install-Module PSWriteOffice
Install-Module M365Documentation

```

### Basic Usage to create docx

This section covers basic functionality for interactive usage. Advanced use cases like creating your own app registration is covered in the [advanced usage](https://github.com/ThomasKur/M365Documentation/blob/master/AdvancedUsage.md) section.

```powershell

# Connect to your tenant
Connect-M365Doc

# Collect information 
$Selection = Get-M365DocValidSection | Out-GridView -OutputMode Multiple
$Sections = $Selection | Select-Object -ExpandProperty SectionName
$Components = $Selection | Select-Object -ExpandProperty Component -Unique
$doc = Get-M365Doc -Components $Components -IncludeSections $Sections

# Output the documentation to a Word file
$doc | Write-M365DocWord -FullDocumentationPath "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc.docx"


```

## Sections which you can choose from

_Component: AzureAD_
AADAdministrativeUnit
AADAuthMethod
AADBranding
AADConditionalAccess
AADConditionalAccessSplit
AADDirectoryPimRole
AADDirectoryRole
AADDomain
AADIdentityProvider
AADOrganization
AADPolicy
AADSubscription

_Component: CloudPrint_
CPConnector
CPPrinter

_InformationProtection_
MIPLabel

_Intune_
MdmAdmxConfigurationProfile
MdmAppleConfiguration
MdmAutopilotProfile
MdmCompliancePolicy
MdmConfigurationPolicy
MdmConfigurationProfile
MdmDeviceAssignmentFilter
MdmDeviceCategory
MdmEnrollmentConfiguration
MdmExchangeConnector
MdmPartner
MdmPowerShellScript
MdmRoles
MdmShellScript
MdmSecurityBaseline
MdmTermsAndCondition
MdmWindowsUpdate
MobileApp
MobileAppConfiguration
MobileAppDetailed
MobileAppManagement

_Windows365_
W365Image
W365OnPremConnection
W365ProvisionProfile
W365UserSetting

## Supported Components

### Microsoft Endpoint Manager / Intune

The following entities are documented:

- Configuration Policies
- Compliance Policies
- Device Enrollment Restrictions
- Terms and Conditions
- Applications (Only Assigned)
- Application Protection Policies
- AutoPilot Configuration
- Enrollment Page Configuration
- Apple Push Certificate
- Apple VPP
- Device Categories
- Exchange Connector
- Application Configuration
- PowerShell Scripts
- ADMX backed Configuration Profiles
- Security Baseline
- Custom Roles

### Azure AD

The following entities are documented:

- Azure AD Conditional Access Policies
- Translate referenced IDs to real object names (users, groups, roles and applications)
- Domains
- Feature Rollout Policy
- Authentication policies
- Role Assignments & PIM Roles
- Mobile Device Management Policies
- Subscriptions / SKU
- Organizational Settings
- Administrative Units

### Cloud Print

The following entities are documented:

- Printers
- Connectors
- Printer Shares

### Microsoft Information Protection

The following entities are documented:

- Labels

### Windows 365 (CloudPC)

- Device Images
- Provisioning Profiles
- User Settings
- On-premises Connections

## Issues / Feedback

For any issues or feedback related to this module, please register for GitHub, and post your inquiry to this project's issue tracker.

## Thanks to

@MEM_MVP for the continuous feedback and 10000 translations!!!! Thank you!

@Microsoftgraph for the PowerShell Examples: <https://github.com/microsoftgraph/powershell-intune-samples>

@PrzemyslawKlys for the PSWriteWord Module, which enables the creation of the Word file. <https://github.com/EvotecIT/PSWriteOffice>

@MScholtes for the Transponse-Object example <https://github.com/MScholtes/TechNet-Gallery>

@ylepine for the contribution to support Intune Settings catalog

@johofer contribution to remove base64 encoded images from the documentation.

![Created by baseVISION](https://www.basevision.ch/wp-content/uploads/2015/12/baseVISION-Logo_RGB.png)
