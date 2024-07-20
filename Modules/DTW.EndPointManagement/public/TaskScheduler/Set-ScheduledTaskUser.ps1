function Set-ScheduledTaskUser {
<#
    .SYNOPSIS
		Synopsis text goes here
		
    .DESCRIPTION
		Description text goes here

    .EXAMPLE
		Command example goes here

    .INPUTS

    .OUTPUTS

    .NOTES
		Created:    26/10/2023
		Author:     Mark White
		Version:    0.0.1
		Updated:    
		History:    0.0.1 - Initial release
		
#>

	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param (
		[Parameter(
				   Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true)]
		[Alias("HOSTNAME")]
		[String[]]$ComputerName,
		[Parameter(
				   Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true)]
		[Alias("Run As User")]
		[String[]]$RunAsUser,
		[Parameter(Mandatory = $true)]
		[String[]]$Password,
		[Parameter(
				   Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true)]
		[String[]]$TaskName
	)
	
	
	Process
	{
		Write-Verbose  "Updating: $($_.'TaskName')"
		if ($pscmdlet.ShouldProcess($computername, "Updating Task: $TaskName "))
		{
			Write-Verbose "schtasks.exe /change /s $ComputerName /RU $RunAsUser /RP $Password /TN `"$TaskName`""
			$strcmd = schtasks.exe /change /s "$ComputerName" /RU "$RunAsUser" /RP "$Password" /TN "`"$TaskName`"" 2>&1
			Write-Host $strcmd
		}
	}
}
