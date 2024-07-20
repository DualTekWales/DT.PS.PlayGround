function Update-PowerCLIConfiguration {
<#
    .SYNOPSIS
		Synopsis text goes here
		
    .DESCRIPTION
		Updates the PowerCLI Configuration to ignore certificate warnings and to not participate in the Customer Experience Program.
		
	.PARAMETER Param1
		Param1 text goes here
		
	.PARAMETER Param2
		Param2 text goes here
		
    .EXAMPLE
		Command example goes here
		
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
[CmdletBinding()]
param ()
    #IgnoreCertificate
    Set-PowerCLIConfiguration -Scope User -InvalidCertificateAction Ignore -Confirm:$false

    #Don't participate in the customer experience program
    Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false
}