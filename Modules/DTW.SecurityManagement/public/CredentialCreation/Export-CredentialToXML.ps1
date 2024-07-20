function Export-CredentialToXML {
<#
	.SYNOPSIS
	    Save credential set as XML file to import into powershell sessions

	.DESCRIPTION
	    Use saved credential set to connect to systems and services using powershell
	    
	.PARAMETER FileName
	    Pass descriptive name for saved file

	.INPUTS
	    None.

	.OUTPUTS
	    CLIXML file with credentials

	.NOTES
		Created:    26/10/2023
		Author:     Mark White
		Version:    0.0.7
		Updated:    14/11/2023
		History:    0.0.1 - Initial release
					0.0.2 - Get-CredentialExportToXML function renamed to New-CredentialExportToXML    
					0.0.3 - New-CredentialExportToXML function renamed to Export-CredentialToXML
					0.0.4 - Added synopsis & description text
					0.0.5 - Updated .NOTES Section
					0.0.6 - Updated .EXAMPLE Section
					0.0.7 - Added Write-LogEntry command
	    
	.EXAMPLE
	    Export-CredentialToXML -FileName <descriptivename>
	    
	    Prompts user for username & password. Encrypts the password and saves the credentials at
	    C:\Users\$env:USERNAME\OneDrive\Documents\WindowsPowerShell\Credentials\$env:COMPUTERNAME\<descriptivename>.xml
	    C:\Users\$env:USERNAME\OneDrive - OrganisationName\Documents\WindowsPowerShell\Credentials\$env:COMPUTERNAME\<descriptivename>.xml
	    C:\Users\$env:USERNAME\Documents\WindowsPowerShell\Credentials\$env:COMPUTERNAME\<descriptivename.xml
	    
#>
    
    [CmdletBinding()]
    Param (
        [Parameter()]
        [string]$FileName
    )

    Get-Elevation

    Write-LogEntry
    
    $ProfileCredentialFolder = "$WindowsPowerShellPath\Credentials\$env:COMPUTERNAME"
    if (!(Test-Path -Path $ProfileCredentialFolder))
    {
        New-Item -ItemType Directory -Path $ProfileCredentialFolder
        Write-Host " Local Credentials Folder Created on $env:COMPUTERNAME" -ForegroundColor Green
    }
    else {
        Write-Host " Local Credential Folder already exists on $env:COMPUTERNAME" -ForegroundColor Magenta
    }
    
    $Credentials = Get-Credential
    Export-Clixml -Path "$ProfileCredentialFolder\$FileName.xml" -InputObject $Credentials

}