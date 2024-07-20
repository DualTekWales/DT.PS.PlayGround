Function Get-RemoteScheduledTask {
<#
	 .Synopsis
	  Gets the task definition object of a scheduled task that is registered on a remote computer.

	 .Description
	  The Get-RemoteScheduledTask cmdlet gets the task definition object of a scheduled task that is registered on a remote computer.

	 .Parameter ComputerName
	  Name of the remote computer

	 .Example 
	  Get-RemoteScheduledTask -ComputerName "SERVER01" -Credential $(Get-Credential)
	
	.NOTES
		Created:    26/10/2023
		Author:     Mark White
		Version:    0.0.1
		Updated:    
		History:    0.0.1 - Initial release
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]$ComputerName,
		[Parameter(Mandatory = $false)]
		[pscredential]$Credential
	)
	
	begin { }
	
	process
	{
		$Tasks = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
			Get-ScheduledTask | Where-Object { ($_.TaskPath -eq "\") -and ($_.State -Ne "Disabled") }
		}
	}
	
	end
	{
		Format-RemoteScheduledTasks $Tasks
		return $Tasks
	}
}