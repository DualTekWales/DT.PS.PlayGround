function Search-PowerShellScripts {
<#
.SYNOPSIS
 Searches PS1 files for a word or phrase
.DESCRIPTION
 Given a search phrase and location, will look in the code for the search string, then display matches in a grid view.  Any items selected will be opened in PowerShell ISE.
.NOTES
Created:    26/10/2023
Author:     Mark White
Version:    0.0.1
Updated:    
History:    0.0.1 - Initial release
.PARAMETER SearchPhrase
 Required, what search string to look for in the PowerShell files
.PARAMETER Path
 In what folder to search (limit one). Default is My Documents
.PARAMETER IncludeAllPSFiles
 If specified, will include PowerShell modules (psm1) and manifests (psd1); default is just PowerShell script (PS1) files.  
.EXAMPLE
 Search-Script 'childitem' 
.EXAMPLE
 Search-Script -SearchPhrase "credential" -Path 'C:\Documents\WindowsPowerShell\'
#>
[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		$SearchPhrase,
		$Path = [Environment]::GetFolderPath('MyDocuments'),
		[switch]$IncludeAllPSFiles = $false
	)
	$psfilter = "*.ps1"
	if ($IncludeAllPSFiles)
	{
		$psfilter = "*.ps*1"
	}
	Get-ChildItem -Path $Path -Filter $psfilter -Recurse -ErrorAction SilentlyContinue |
	Select-String -Pattern $SearchPhrase -List |
	Select-Object -Property Path, Line, @{ l = "dateModified"; e = { (Get-Item $_.path).LastWriteTime } } |
	Out-GridView -Title "Choose a Script containing $SearchPhrase to open in ISE" -PassThru |
	ForEach-Object -Process {
		powershell_ise.exe $_.Path
	}
} #end function