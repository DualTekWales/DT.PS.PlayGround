function Convert-SecureStringToString {
<#
	.SYNOPSIS
	    Converts a SecureString value back to a plaintext string
	.DESCRIPTION
	    Converts a SecureString value back to a plaintext string
	.PARAMETER SecureString
	    The SecureString that you want to get back to being plaintext
	.EXAMPLE
	    $SecureString = Read-Host -Prompt 'Enter a string' -AsSecureString
	    #Let's say you entered the string 'Password' without quotes

	    Convert-SecureStringToString -SecureString $SecureString

	    Password
	.NOTES
        Created:    26/10/2023
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release

#>

    [CmdletBinding(ConfirmImpact='Low')]
    [OutputType('string')]
    Param (
        [Parameter(Mandatory)]
        [securestring] $SecureString
    )

    begin {
        Write-Verbose -Message "Starting [$($MyInvocation.Mycommand)]"
    }

    process {
        $UserName = 'domain\user'
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $SecureString
        Write-Output -InputObject $Credential.GetNetworkCredential().Password
    }

    end {
        Write-Verbose -Message "Ending [$($MyInvocation.Mycommand)]"
    }
}
