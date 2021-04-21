# Microsoft 365 Automatic Documentation

<img align="right" src="https://github.com/ThomasKur/M365Documentation/raw/main/Logo/M365DocumentationLogo.png" width="300px" alt="Automatic M365 Documentation Logo">Automatic Microsoft 365 Documentation to simplify the life of admins and consultants. You can automatically document systems like:

- Microsoft Endpoint Manager / Intune
- Azure AD

_This list will expand in the near future._

This is the successor to the IntuneDocumentation module and has much more options like:

- Output to Json
  - Backup your configuration and create documentation later
  - Compare your configuration over time for example with <http://www.jsondiff.com/>
- Output to CSV
- Flexible Authentication with MSAL.PS
  - Support for Certificate and Secret based Authentication

Through the new architecture much other features will follow in the near future.

## Usage

### Installation

The required modules are fully available in the PowerShell Gallery and therefore simple to install.

```powershell

Install-Module MSAL.PS
Install-Module PSWriteWord
Install-Module M365Documentation -AllowPrerelease

```

### Basic Usage to create docx

This section covers basic functionality for interactive usage. Advanced use cases like creating your own app registration is covered in the [advanced usage](https://github.com/ThomasKur/M365Documentation/blob/master/AdvancedUsage.md) section.

```powershell

# Connect to your tenant
Connect-M365Doc

# Collect information for component Intune as an example 
$doc = Get-M365Doc -Components Intune -ExcludeSections "MobileAppDetailed"

# Output the documentation to a Word file
$doc | Write-M365DocWord -FullDocumentationPath "c:\temp\$($doc.CreationDate.ToString("yyyyMMddHHmm"))-WPNinjas-Doc.docx"


```

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
- Translate referenced id's to real object names (users, groups, roles and applications)

## Issues / Feedback

For any issues or feedback related to this module, please register for GitHub, and post your inquiry to this project's issue tracker.

## Thanks to

@MEM_MVP for the continious feedback and 10000 translations!!!! Thank you!

@Microsoftgraph for the PowerShell Examples: <https://github.com/microsoftgraph/powershell-intune-samples>

@guidooliveira / @PrzemyslawKlys for the PSWriteWord Module, which enables the creation of the Word file. <https://github.com/EvotecIT/PSWriteWord>

@MScholtes for the Transponse-Object example <https://github.com/MScholtes/TechNet-Gallery>


![Created by baseVISION](https://www.basevision.ch/wp-content/uploads/2015/12/baseVISION-Logo_RGB.png)
