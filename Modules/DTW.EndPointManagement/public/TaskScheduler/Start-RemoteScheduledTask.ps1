Function Start-RemoteScheduledTask {
<#
	.Synopsis
		  Starts one or more instances of a scheduled task on a remote computer.

	.Description
		  The Start-ScheduledTask cmdlet starts a registered background task asynchronously on a remote computer.

	.Parameter ScheduledTask
		  ScheduleTask Object retrieved from Get-RemoteScheduledTask

	.Example
		  $Tasks = Get-RemoteScheduledTask -ComputerName "SERVER01" -Credential $(Get-Credential)
		  $Tasks[0] | Start-RemoteScheduledTask
	
	.NOTES
		Created:    26/10/2023
		Author:     Mark White
		Version:    0.0.1
		Updated:    
		History:    0.0.1 - Initial release
	
#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline, Mandatory = $true)]
		[Microsoft.Management.Infrastructure.CimInstance]$ScheduledTask
	)
	
	begin
	{
	}
	
	process
	{
		Invoke-Command -ComputerName $ScheduledTask.PSComputerName -ScriptBlock {
			param ($ScheduledTask)
			Write-Host "Starting: $($ScheduledTask.TaskName)" -ForegroundColor "Green"
			$ScheduledTask | Start-ScheduledTask
		} -ArgumentList $ScheduledTask
	}
}