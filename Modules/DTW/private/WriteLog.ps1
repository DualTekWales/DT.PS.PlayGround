function WriteLog {
<#
    .SYNOPSIS
    Write text to this script's log file
    .DESCRIPTION
    Write text to this script's log file
    .PARAMETER InformationType
    This parameter contains the information type prefix. Possible prefixes and information types are:
        I = Information
        S = Success
        W = Warning
        E = Error
        - = No status
    .PARAMETER Text
    This parameter contains the text (the line) you want to write to the log file. If text in the parameter is omitted, an empty line is written.
    .PARAMETER LogFile
    This parameter contains the full path, the file name and file extension to the log file (e.g. C:\Logs\MyApps\MylogFile.log)
    .EXAMPLE
    WriteLog -InformationType "I" -Text "Copy files to C:\Temp" -LogFile "C:\Logs\MylogFile.log"
    Writes a line containing information to the log file
    .Example
    WriteLog -InformationType "E" -Text "An error occurred trying to copy files to C:\Temp (error: $($Error[0]))!" -LogFile "C:\Logs\MylogFile.log"
    Writes a line containing error information to the log file
    .Example
    WriteLog -InformationType "-" -Text "" -LogFile "C:\Logs\MylogFile.log"
    Writes an empty line to the log file
    .Notes
	Created:    26/10/2023
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
#>
    [CmdletBinding()]
    Param( 
        [Parameter(Mandatory = $true, Position = 0)][ValidateSet("I", "S", "W", "E", "-", IgnoreCase = $True)][String]$InformationType,
        [Parameter(Mandatory = $true, Position = 1)][AllowEmptyString()][String]$Text,
        [Parameter(Mandatory = $false, Position = 2)][String]$LogFile = "C:\Logs\",
        [Parameter(Mandatory = $false, Position = 3)][switch]$Console
    )
 
    begin {
    }
 
    process {
        # Create new log file (overwrite existing one should it exist)
        if (! (Test-Path $LogFile) ) {    
            # Note: the 'New-Item' cmdlet also creates any missing (sub)directories as well (works from W7/W2K8R2 to W10/W2K16 and higher)
            New-Item $LogFile -ItemType "file" -force | Out-Null
        }

        $DateTime = (Get-Date -format dd-MM-yyyy) + " " + (Get-Date -format HH:mm:ss)
 
        if ( $Text -eq "" ) {
            Add-Content $LogFile -value ("") # Write an empty line
        }
        else {
            Add-Content $LogFile -value ($DateTime + " " + $InformationType.ToUpper() + " - " + $Text)
        }
        if ($Console) {
        # Besides writing output to the log file also write it to the console
        Write-host "$($InformationType.ToUpper()) - $Text"
        }
        else {
            
        }
    }
 
    end {
    }
}