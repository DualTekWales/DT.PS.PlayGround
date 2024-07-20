function Get-ADAccountLock {
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
Param (
    [Parameter()]
    [string]$UserLogin
)
$Check = Get-AdUser -Identity $UserLogin -Properties LockedOut | Select-Object LockedOut
if ($Check -eq $true)
{
    Unlock-ADAccount -Identity $UserLogin
    "Account is locked"
}
else
{
    Clear-Host
    "Account is not locked"
}
	Read-Host
	
}
	