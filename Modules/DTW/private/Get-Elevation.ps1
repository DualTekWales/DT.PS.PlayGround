function Get-Elevation {
<#
    .NOTES
		Created:    28/03/2022 12:22
		Version:	1.0.1
		Author:     Mark White
		Updated:    
		Version:    1.0.1 - Initial script release
		
#>
	#Admin Privleges Check
	$AdminConsole = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
	
	if ($AdminConsole -like "False*")
	{
		Write-Warning $ElevationWarning
		Write-Host ' '
		Break
	}
}