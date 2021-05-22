# Translate API names and help to improve the tranlsation feature

When using the _Optimize-M365Doc -UseTranslationFiles_ the OData api names will be translated to the labels used in the Microsoft Portals. Some of the documented objects are not translated due to high effort which is needed to do this. But you can help translating them and make the project better for everybody. With the new _Invoke-M365DocTranslationUI_ command this is really simple.

|  Image  |  Description |
|--- |--- |
| <img src="https://raw.githubusercontent.com/ThomasKur/M365Documentation/main/Images/Translate-1-Get-M365Doc.png">  | Most often you have already created a documentation and got the message that not all translations were available. Then you can start with step 3, otherwise you can now create a documentation from your environment. |
| <img src="https://raw.githubusercontent.com/ThomasKur/M365Documentation/main/Images/Translate-2-Optimize-M365Doc.png">  | Optimize the just collected infomration with the _Optimize-M365Doc -UseTranslationFiles_ command.|
| <img src="https://raw.githubusercontent.com/ThomasKur/M365Documentation/main/Images/Translate-3-NotTranslatedFiles.png">  |The command will show you all OData api names which are not full translated. |
| <img src="https://raw.githubusercontent.com/ThomasKur/M365Documentation/main/Images/Translate-4-Invoke-M365DocTranslationUI.png">  |You can now start the new translation UI by executing _Invoke-M365DocTranslationUI_. |
| <img src="https://raw.githubusercontent.com/ThomasKur/M365Documentation/main/Images/Translate-5-Step1.png">  | Select the OData api name which you want to improve. |
| <img src="https://raw.githubusercontent.com/ThomasKur/M365Documentation/main/Images/Translate-6-Step2.png">  | In this step you can translate all properties. You should follow these guidelines:

- Use the exact same name as it is in the Microsoft Portal
- US English names
- Section name
  - Use "Basic" or Empty when no section can be dedected in the Microsoft Portal
  - Use "/" to separate Sub sections

   |
| <img src="https://raw.githubusercontent.com/ThomasKur/M365Documentation/main/Images/Translate-7-Step3.png">  | Click on _Save for local testing_. This saves the translation file into the local module directory. |
| <img src="https://raw.githubusercontent.com/ThomasKur/M365Documentation/main/Images/Translate-8-Step3-Test.png">  | You can now execute the _Optimize-M365Doc -UseTranslationFiles_ command again and create a new Word documentation file.  |
| <img src="https://raw.githubusercontent.com/ThomasKur/M365Documentation/main/Images/Translate-9-Step3-Review.png">  | Open the newly created Wiord file and check if the translation is as wished. If yes continue to the next step. Otherwise go back to step 6. |
| <img src="https://raw.githubusercontent.com/ThomasKur/M365Documentation/main/Images/Translate-10-Step4.png">  | Start the _Invoke-M365DocTranslationUI_ again and select the translated OData api name and then submit the translation in the _4 - Submit_ register. |
