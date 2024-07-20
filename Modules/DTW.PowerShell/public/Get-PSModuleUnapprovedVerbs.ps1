function Get-PSModuleUnapprovedVerbs {
<#
    .DESCRIPTION
	
	.EXAMPLE
		Get-PSModuleUnapprovedVerbs -Module ActiveDirectory
	
	.EXAMPLE
		Get-PSModuleUnapprovedVerbs -Module Dualtek.Wales.PowerShell
		
	.NOTES
		Created:    26/10/2023
		Author:     Mark White
		Version:    0.0.1
		Updated:    
		History:    0.0.1 - Initial release

#>
	[CmdletBinding()]
	param (
		[Parameter()]
		[System.String]$ModuleName
		
	)
	
	Get-Command -Module $ModuleName | Where-Object Verb -NotIn (Get-Verb).Verb
	
}
