function Connect-PMPLive {
	<#
		.DESCRIPTION
			Establishes a PowerShell session to the Password Manager Pro LIVE Server
	
		.EXAMPLE
			Connect-PMPLive
		
		.NOTES
			Created:    11/10/2023
			Version:	0.0.1
			Author:     Mark White
			Updated:    
			History:    0.0.1 - Initial script release
	
	#>
		#Requires -Module Ipo.Pmp
		
	[CmdletBinding()]
	param ()

		[string]$FunctionName = $PSCmdlet.MyInvocation.MyCommand.Name
		WriteLog "I" "START FUNCTION - $FunctionName" -LogFile "$ScriptLogs\$FunctionName.log"
	
		WriteLog "I" "Getting PMP API Key" -LogFile "$ScriptLogs\$FunctionName.log"
		$PMPAPIKey = Get-Content -Path "$StoredCreds\PMPLiveAPIKey.txt"
		WriteLog "S" "Successfully got PMP API Key"-LogFile "$ScriptLogs\$FunctionName.log"

		WriteLog "I" "Converting PMP API Key to SecureString"-LogFile "$ScriptLogs\$FunctionName.log"
		$PMPSecureString = $PMPAPIKey | ConvertTo-SecureString
		WriteLog "S" "Successfully converted PMP API key to a securestring"-LogFile "$ScriptLogs\$FunctionName.log"
		
		# Decrypt PMPApiKey
		WriteLog "I" "Decrypt PMP API Key" -LogFile "$ScriptLogs\$FunctionName.log"
		$decryptedPMPAPI = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PMPSecureString)
		$decryptedPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($decryptedPMPAPI)
		WriteLog "S" "Successfully decrypted PMP API Key"-LogFile "$ScriptLogs\$FunctionName.log"
		
		WriteLog "I" "Create PS Session to the PMP Server $PMPliveserver"-LogFile "$ScriptLogs\$FunctionName.log"
		New-PmpSession -Server $PMPLiveServer -AuthToken $decryptedPassword -Port $PMPPort | Out-Null
		WriteLog "S" "Sucessfully connected to the $PMPLiveServer server" -LogFile "$ScriptLogs\$FunctionName.log"

		WriteLog "I" "END FUNCTION - $FunctionName" -LogFile "$ScriptLogs\$FunctionName.log"
	}