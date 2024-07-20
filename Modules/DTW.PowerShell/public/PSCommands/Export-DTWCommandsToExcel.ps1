function Export-DTWCommandsToExcel {
<#
    .SYNOPSIS
		Function to export ALL Private & Public functions from all DTW PowerShell Modules, writing the output to an Excel document
		
    .DESCRIPTION
		Function to export ALL Private & Public functions from all DTW PowerShell Modules, writing the output to an Excel document
	
	.EXAMPLE
		Export-DTWCommandsToExcel
		
    .NOTES
		Created:    26/10/2023
		Author:     Mark White
		Version:    0.0.5
		Updated:    14/11/2023
		History:    0.0.1 -	Initial script creation
					0.0.2 -	Changed Remove-Item to Move-ToRecycleBin command
					0.0.3 -	Changed function name from Export-DualTekCommandsToExcel to Export-DTWCommandsToExcel
						  -	Changed the exported filename from DualTekCommands-Exported to DTWCommands-Exported
						  -	Changed the -TableName of the exported file from DualTekCommands to DTWCommands
						  -	Added Notification on completion of the command Send-OSNotification
					0.0.4 -	Change date format on $DateNow variable
					0.0.5 - Added -All to main Get-Command function
						  - Added additional properties to the Select-Object
						  - Updated the help section of the function
		
#>	
	$DateNow = Get-Date -Format yyyy-MM-dd
	
	$xlsxfile = "$ScriptOutput\$DateNow - DTWCommands-Exported" + ".xlsx"
	
	if (Test-Path $xlsxfile)
	{
		Remove-Item $xlsxfile
	}
	
	Start-Sleep 2
	
	Get-Command -Module DTW* -All | Select-Object -Property Source, Name, CommandType, Version | Sort-Object Source, Name | Export-Excel $xlsxfile -AutoSize -Startrow 1 -TableName DTWCommands
	
}