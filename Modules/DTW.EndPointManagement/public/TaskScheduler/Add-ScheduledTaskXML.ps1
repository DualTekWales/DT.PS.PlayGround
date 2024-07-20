function Add-ScheduledTaskXML {
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
	[CmdletBinding()]
	param(
		[Parameter(
			Mandatory = $true,
			HelpMessage = "Enter a valid XML file path",
			ValueFromPipeline = $true,
			ValueFromPipelinebyPropertyName = $true,
			Position = 0
		)]
		[ValidateNotNullOrEmpty()]
		[string] $XMLFile,
		[Parameter(
			Mandatory = $false,
			HelpMessage = "Enter a task name",
			ValueFromPipeline = $true,
			ValueFromPipelinebyPropertyName = $true,
			Position = 1
		)]
		[string] $TaskName = $null,
		[Parameter(
			Mandatory = $false,
			HelpMessage = "Enter user name",
			ValueFromPipeline = $true,
			ValueFromPipelinebyPropertyName = $true,
			Position = 2
		)]
		[string] $User = $null,
		[Parameter(
			Mandatory = $false,
			HelpMessage = "Enter password",
			ValueFromPipeline = $true,
			ValueFromPipelinebyPropertyName = $true,
			Position = 3
		)]
		[string] $Password = $null		
	)
	
	if((Test-Path -Path $XMLFile) -and ($XMLFile.EndsWith(".xml"))){
		$taskExists = Get-ScheduledTask | Where-Object { $_.TaskName -like $TaskName }
		if($taskExists){
			Write-Host "$TaskName already exists" -foreground yellow
		}
		else{
			if((String-IsNullOrEmpty $TaskName)){
				$TaskName = (Get-Item $XMLFile).BaseName
				$taskExists = Get-ScheduledTask | Where-Object { $_.TaskName -like $TaskName }
			}			
			if($taskExists){
				Write-Host "$TaskName already exists" -foreground yellow				
			}			
			else{
				if((String-IsNullOrEmpty $Password) -or (String-IsNullOrEmpty $User)){
					Register-ScheduledTask -Xml (Get-Content $XMLFile | out-string) -TaskName $TaskName | out-null
				}
				else{
					Register-ScheduledTask -Xml (Get-Content $XMLFile | out-string) -TaskName $TaskName -User $User -Password $Password | out-null
				}
				Enable-ScheduledTask -TaskName $TaskName
			}
		}
	}
	else{
		Write-Host "There is no valid XML file." -foreground red
	}
}