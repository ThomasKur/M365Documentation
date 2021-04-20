function Write-Log {
    <#
    .DESCRIPTION
    Write text to a logfile with the current time.

    .PARAMETER Message
    Specifies the message to log.

    .PARAMETER Type
    Type of Message ("Info","Debug","Warn","Error").

    .PARAMETER OutputMode
    Specifies where the log should be written. Possible values are "Console","LogFile" and "Both".

    .PARAMETER Exception
    You can write an exception object to the log file if there was an exception.

    .EXAMPLE
    Write-Log -Message "Start process XY"

    .NOTES
    This function should be used to log information to console or log file.
    #>
    param(
        [Parameter(Mandatory=$true,Position=1)]
        [String]
        $Message
    ,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info","Debug","Warn","Error")]
        [String]
        $Type = "Debug"

    ,
        [Parameter(Mandatory=$false)]
        [Exception]
        $Exception
    )
    $LogFilePathFolder     = Join-Path -Path $Env:TEMP -ChildPath $ScriptName
    $OutputMode  = "Console" # "Console-LogFile","Console-WindowsEvent","LogFile-WindowsEvent","Console","LogFile","WindowsEvent","All"
    $DefaultLogWindowsEventSource = "IntuneDocumentation"
    $DefaultLogWindowsEventLog = "CustomPS"
    $LogFilePath = "$LogFilePathFolder\IntuneDocumentation_$(Get-Date -uformat %Y%m%d%H%M).log"
    $DateTimeString = Get-Date -Format "yyyy-MM-dd HH:mm:sszz"
    $Output = ($DateTimeString + "`t" + $Type.ToUpper() + "`t" + $Message)
    if($Exception){
        $ExceptionString =  ("[" + $Exception.GetType().FullName + "] " + $Exception.Message)
        $Output = "$Output - $ExceptionString"
    }
    if ($OutputMode -eq "Console" -OR $OutputMode -eq "Console-LogFile" -OR $OutputMode -eq "Console-WindowsEvent" -OR $OutputMode -eq "All") {
        if($Type -eq "Error"){
            Write-Error $output
        } elseif($Type -eq "Warn"){
            Write-Warning $output
        } elseif($Type -eq "Debug"){
            Write-Debug $output
        } else{
            Write-Verbose $output -Verbose
        }
    }
    if ($OutputMode -eq "LogFile" -OR $OutputMode -eq "Console-LogFile" -OR $OutputMode -eq "LogFile-WindowsEvent" -OR $OutputMode -eq "All") {
        try {
            Add-Content $LogFilePath -Value $Output -ErrorAction Stop
        } catch {
            exit 99001
        }
    }
    if ($OutputMode -eq "Console-WindowsEvent" -OR $OutputMode -eq "WindowsEvent" -OR $OutputMode -eq "LogFile-WindowsEvent" -OR $OutputMode -eq "All") {
        try {
            New-EventLog -LogName $DefaultLogWindowsEventLog -Source $DefaultLogWindowsEventSource -ErrorAction SilentlyContinue
            switch ($Type) {
                "Warn" {
                    $EventType = "Warning"
                    break
                }
                "Error" {
                    $EventType = "Error"
                    break
                }
                default {
                    $EventType = "Information"
                }
            }
            Write-EventLog -LogName $DefaultLogWindowsEventLog -Source $DefaultLogWindowsEventSource -EntryType $EventType -EventId 1 -Message $Output -ErrorAction Stop
        } catch {
            exit 99002
        }
    }
}