Function WriteLog2 {
<#
    .SYNOPSIS
	    This function writes logs.
	    
    .DESCRIPTION
	    This function writes, appends and exports logs.
	    
    .PARAMETER LogMessage
    	Mandatory - your log message.
    .PARAMETER LogSeverity
    	Mandatory - severity of your message.
    .PARAMETER LogPath
	    Not mandatory - path to location where you want the file to be saved.
	    If LogPath is not declared, folder will be created inside $env:APPDATA\BMX\Logs

    .NOTES
        Created:    26/10/2023
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release

	    If LogPath is not declared, logs will end in $env:TEMP\Logs.
	    If LogFileName if not declared, hostname will be used as one.

    .EXAMPLE
    	WriteLog -LogMessage "Your_Message" -LogSeverity Information -LogPath "C:\" -LogFileName "Your_File_Name"
    #>
    [CmdletBinding()]
    param(

        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('I', 'W', 'A', 'E')]
        [string]$LogSeverity = 'I',
        [Parameter(Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$LogMessage,
        [Parameter(Mandatory = $false)]
        [string]$LogPath,
        [Parameter(Mandatory = $false)]
        [string]$LogFileName = "$FunctionName"
    )
    BEGIN {
        if ($LogPath) {
            New-Item -Path "$LogPath" -ItemType Directory -Force | Out-Null
        } 
        elseif (!$LogPath) {
            New-Item -Path "C:\Logs" -ItemType Directory -Force | Out-Null
            $LogPath = "C:\Logs"
        }
        else {
            Write-Error -Message "Unable to create logpath '$LogPath'. Error was: $_" -ErrorAction Stop
        }
    }
    PROCESS {
        if ($LogFileName) {
            $LogFileName = "$LogFileName" + ".log"
        }
        elseif (!$LogFileName) {
            $LogFileName = "$env:COMPUTERNAME" + ".log"
        }
        $ReportLogTable = [PSCustomObject]@{
            'TimeAppended' = (Get-Date -Format "yyyy-MM-dd @ HH:mm")
            'LogMessage'   = $LogMessage
            'LogSeverity'  = $LogSeverity
        }
    }
    END {
        $ReportLogTable | Add-Content -Path "$LogPath\$LogFileName"
    }
}