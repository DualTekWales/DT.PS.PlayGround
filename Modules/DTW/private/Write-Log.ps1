function Write-Log() {
<#
    .SYNOPSIS
		Synopsis text goes here
			
    .NOTES
	Created:    26/10/2023
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
		
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("E","W","I","S","-")]
        [string]$LogLevel = "I",
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true, position=1)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogMessage")]
        [string]$LogContent,
        [Parameter(Mandatory=$false)]
        [Alias('Path')]
        [string]$LogPath,
        [Parameter()]
        [string]$LogFileName = "$FunctionName" + ".log"

    )
    Begin {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
       # $verbosePreference = 'Continue'

        if ($LogPath) {
            New-Item -Path "$LogPath" -ItemType Directory -Force | Out-Null
        } 
        elseif (!$LogPath) {
            New-Item -Path "C:\Logs" -ItemType Directory -Force | Out-Null
            $LogPath = "C:\Logs"
        }
        else {
            Write-Error -Message "Unable to create LogPath '$LogPath'. Error was: $_" -ErrorAction Stop | Write-Log Error "$_"
        }
    
    }
    Process {
		if ((Test-Path $LogFileName)) {
			$logSize = (Get-Item -Path $LogFileName).Length/1MB
			$maxLogSize = 5
		}
        # Check for file size of the log. If greater than 5MB, it will create a new one and delete the old.
        if ((Test-Path $LogFileName) -AND $LogSize -gt $MaxLogSize) {
            Write-Error "Log file $LogFileName already exists and file exceeds maximum file size. Deleting the log and starting fresh."
            Rename-Item -Path $LogFileName -NewName "$LogFileName" + "-old" -Force
            $newLogFile = New-Item $LogPath -Force -ItemType File
        }
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif (-NOT(Test-Path $LogFileName)) {
            Write-Verbose "Creating $LogFileName."
            $newLogFile = New-Item $LogFileName -Force -ItemType File
        }
        else {
            # Nothing to see here yet.
        }
        # Format Date for our Log File
        $formattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($level) {
            'Error' {
                Write-Error $LogContent
                $LogLevel = 'ERROR:'
            }
            'Warn' {
                Write-Warning $LogContent
                $LogLevel = 'WARNING:'
            }
            'Info' {
                Write-Verbose $LogContent
                $LogLevel = 'INFO:'
            }
        }
        # Write log entry to $Path
        "$formattedDate $LogLevel $LogFileName" | Out-File -FilePath $LogPath\$LogFileName -Append
    }
    End {
    }
}