function Set-2k8ScheduledTask {
<#
	.SYNOPSIS
	
	
	.DESCRIPTION
	
	
	.EXAMPLE
	
	
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
		[String[]]$TaskName
	)
	
	Begin
	{
		$ShortDate = [regex]"(?<ShortDate>[0-9]{4}[/.-](?:1[0-2]|0[1-9])[/.-](?:3[01]|[12][0-9]|0[1-9])T(?:2[0-3]|[01][0-9])[:.][0-5][0-9][:.][0-5][0-9])(?<Digits>\.\d*)"
	}
	
	Process
	{
		$XMLIn = schtasks /query /s $ComputerName /tn $TaskName /xml
		If (Test-Path "$Env:TEMP\$($TaskName).xml") `
		{
			Remove-Item "$Env:TEMP\$($TaskName).xml"
		}
		
		foreach ($line in $XMLIn)
		{
			If ($line -match "$ShortDate")
			{
				$line = [regex]::Replace($line, $ShortDate, $($Matches["Shortdate"]))
			}
			
			If ($line.length -gt 1)
			{
				$line | Out-File -Append -FilePath "$Env:TEMP\$($TaskName).xml"
			}
		}
		
		
		if ($pscmdlet.ShouldProcess($ComputerName, "Fixing Task: $TaskName "))
		{
			Write-Verbose "Commandline: schtasks /Create /tn $TaskName /XML $Env:TEMP\$($TaskName).xml /f"
			schtasks /Create /tn $TaskName /XML "$Env:TEMP\$($TaskName).xml" /f
		}
		
		Write-Verbose "Removing $Env:TEMP\$($TaskName).xml"
		
		If (Test-Path "$Env:TEMP\$($TaskName).xml")
		{
			Remove-Item "$Env:TEMP\$($TaskName).xml"
		}
	}
}
