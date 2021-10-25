# Release Notes

## 3.1.1 - 16.08.2021 - Thomas Kurth

- Update Redirect URI in Connect-M365Doc to support PowerShell 7 / .NET Core
- Add support for Intune Settings Catalog (Provided by @ylepine)
- #2 add warning to restart Powershell after the creation of a new app registrations

## 3.1.0 - 18.07.2021 - Thomas Kurth

- Add Cloud Print as new collector
- Add Information Protection as new collector (Only working when running with app registration)
- Bugfix #4 Connect with Secure String
- Add IdentityProvider.Read.All to scopes as it is required by the AzureAD part
- Add Windows 365 as new collector (Beta)

## 3.0.3 - 26.05.2021 - Thomas Kurth

- The Optimize-M365Doc command supports now the -ExcludeValues parameter which will create an empty documentation. 

## 3.0.2 - 26.04.2021 - Thomas Kurth

- Add Translation UI which helps users to simply contribute to the project (Invoke-M365DocTranslationUI).
- Extend Azure AD Documentation

## 3.0.1 - 26.04.2021 - Thomas Kurth

- Fix ParameterDefault on Get-M365Doc
- Add try catch when getting Azure AD groups
- Bugix trim when value is a boolean
- Update translations
- Extend Azure AD Documentation
- Separate Windows Update from Configuration Profile

## 3.0.0 - 19.04.2021 - Thomas Kurth

- Migrated from IntuneDocumentation to M365Documentation module
- Modularized functionality

## 2.0.19 - 02.02.2021 - Thomas Kurth

- AD group Assignments are now documented in a table with intent, count of members and more information about the AD Group itself.
- Add translation for 5 new profiles
- If no translation is available use a pretty print method to improve readability of API names.
- Add possibility to translate Security Baseline, MAM and compliance policy
- Bugfix
  - Spelling errors
  - null byte data in scripts error
  - OMA-URI (Custom Policy) fixed
  - protectedApps in WIP policy now displayed correctly.
  - Firewall rules are now dispayed in word file. Per rule one table row instead of all rules in a single row.
  
## 2.0.18 - 28.07.2020 - Thomas Kurth

- Bugfix to include App Config assignments
- Improve Conditional Access Documentation
- Generate CSV for COnditional Access Documentation

## 2.0.17 - 26.07.2020 - Thomas Kurth

- Bugfix to include MAM assignments
- Add Conditional Access Documentation
- Conditional Access Documentation - Translate referenced id's to real object names (users, groups, roles and applications)

## 2.0.16 - 21.07.2020 - Thomas Kurth

- Added possibility to run the documentation [in background](README.md#use-script-silently) with a custom App Registration

## 2.0.15 - 15.06.2020 - Thomas Kurth

- Add documentation for Security Baseline.
- Add documentation for Custom Roles.

## 2.0.14 - 17.05.2020 - Thomas Kurth

- Using Beta Graph for retieving Apps. This returns also win32 Lob and Office Suite Apps.

## 2.0.13 - 26.04.2020 - Thomas Kurth

- Deactivated Verbose Loging of Intune PS Module
- Bugfix by David Jacobs
- Hide Section Titles when there is no content
- Start adding translations to have the same property names like in the Intune UI instead of just the API names
- Adding additional translation
- Make translations Optional -UseTranslationBeta

## 2.0.12 - 26.03.2020 - Thomas Kurth

- Bugfix: All ADMX settings are now correctly displayed
- Assignments of various elements like Scripts, ADMX, Enrollment Status Page and Windows Hello for Business are now documented
- Section "Enrollment Status Page" renamed to "Enrollment Configuration" because it contains also WHfB, Enrollment Restrictions, ESP, and Enrollment Limits.
- Configuration Profiles are now loaded from the Beta Graph API. Therefore, much more types are returned. For example the Domain Join configuration is now returned.

## 2.0.11 - 30.01.2020 - Thomas Kurth

- Improve Titles in the ESP Page Section

## 2.0.1-10 - 30.01.2020 - Thomas Kurth

- Various Bugfixing due to PSModule generation

## 2.0.0 - 29.01.2020 - Thomas Kurth

- Migrated to PSModule
- Published to PSGallery

## Old History (Before PSModule)

001: First Version
002: SetRegistryKey Function now allows to set empty values
003: Change CreateFolder Function to first create folder and then write the log. Otherwise whe function can fail, when the logfile folder doesn't exist.
004: Improved Log Action
005: Version is now taken from Variable, Log can be written to Windows Event,
        ScriptName does no longer contain Script FileName, which is now available in $CurrentFileName
006: ScriptPath not allways read correctly. Sometimes it was a relative path.
007: Better formating and Option to specify the Save As location
008: Jos Lieben: Fixed a few things and added Conditional Access Policies
009: Thomas Kurth: Adding AutoPilot Information
010: Thomas Kurth: Complete rewriting and using the Intune PowerShell module
        Added Partner Information
011: Added Application Protection Policies
        Tidied up to meet PSScriptAnalyzer Best Practice and removed some whitespace
012: Thomas Kurth: Added new sections:
        - Enrollment Page Configuration
        - Apple Push Certificate
        - Apple VPP
        - Device Categories
        - Exchange Connector
013: Thomas Kurth: Added new Sections:
        - PowerShellScripts
        - Application COnfiguration
        - Added new Template functionality

014: Thomas Kurth
        - Document ADMX backed Profiles
