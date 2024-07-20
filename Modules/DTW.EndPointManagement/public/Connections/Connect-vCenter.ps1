function Connect-vCenter {
<#
	
    .SYNOPSIS
    
    .DESCRIPTION
    
    .PARAMETER VIServer
	
	.EXAMPLE
	
		Connect-vCenter -VIServer CHMGT
	
	.EXAMPLE
	
		Connect-vCenter -VIServer DRMGT
	
	.EXAMPLE
	
		Connect-VIServer -VIServer BOTH
	    
    .NOTES
		Created:    26/10/2023
		Author:     Mark White
		Version:    0.0.1
		Updated:    
		History:    0.0.1 - Initial release
		
    #>
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, HelpMessage = 'vCenter to connect to: CHMGT, DRMGT, or BOTH')]
		[ValidateSet("CHMGT", "DRMGT", "BOTH")]
		[System.String]$VIServer,
		[Parameter(Mandatory = $true, HelpMessage = 'Provide credentials to connect to VIServer')]
		[ParameterType]$CredsToUse
	) # END PARAM
	
	# Import the VMware PowerCLI module, if not already done
	if ($null -eq (Get-Module -Name 'VMware.PowerCLI'))
	{
		Import-Module -Name 'VMware.PowerCLI' -Verbose:$false *> $null
		
		# Disable CEIP and ignore certificate warnings
		Set-PowerCLIConfiguration -Scope User -ParticipateInCeip $false -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
	}

	if ($VIServer.Equals("CHMGT"))
	{
		Connect-VIServer $VIServer -Credential $CredsToUse
		Write-Host -ForegroundColor DarkGreen " Connected to VIServer $VIServer on $WorkSurface"
	} # END IF
	
	elseif ($VIServer.Equals("DRMGT"))
	{
		Connect-VIServer $VIServer -Credential $CredsToUse
		Write-Host -ForegroundColor DarkGreen " Connected to VIServer $VIServer on $WorkSurface"
	} # END ELSEIF
	
	elseif ($VIServer.Equals("BOTH"))
	{
		Connect-VIServer CHMGT, DRMGT -Credential $CredsToUse
		Write-Host -ForegroundColor DarkGreen " Connected to VIServer CHMGT & DRMGT on $WorkSurface"
	} # END ELSEIF
	
	else
	{
		Write-Host -ForegroundColor DarkGreen " A VIServer connection is not required at this time"
	} # END ELSE
	
} # Check This
