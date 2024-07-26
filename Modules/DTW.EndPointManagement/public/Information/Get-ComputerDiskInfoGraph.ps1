function Get-ComputerDiskInfoGraph {
<#
	.SYNOPSIS
	    
	.DESCRIPTION

	.PARAMETER ComputerName

	.PARAMETER DriveType

	.NOTES
		Created:    26/10/2023
		Author:     Mark White
		Version:    0.0.1
		Updated:    
		History:    0.0.1 - Initial release

	.EXAMPLE
		
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.String]$ComputerName = $env:COMPUTERNAME,
        [Parameter()]
        [ValidateSet("2","3","4")]
        [System.String]$DriveType = 3,
		[Parameter()]
		[System.String]$Credentials
    ) 
 
	$diskInfo = Get-WmiObject Win32_LogicalDisk -ComputerName $ComputerName -Filter "DriveType = $DriveType" -Credential $Credentials
	$lines = "="*30
	$used = " "*20
	$free = " "*10
	$thresold=40
	Write-Host
	Write-Host  $lines"Graph"$lines -ForegroundColor Cyan
	Write-Host
	Write-Host $table -NoNewline
	Write-Host " " -BackgroundColor Red -NoNewline
	Write-Host " Used Space" -NoNewline "  "
	Write-Host " " -BackgroundColor Green -NoNewline
	Write-Host " Free Space" -NoNewline
	Write-Host "`n"
	 
		foreach($disk in $diskInfo)
		{ 
		 $usedSize = ($disk.size -$disk.FreeSpace)/$disk.Size
		 $freeDisk =  $disk.FreeSpace/$disk.Size
		 $percentDisk = "{0:P2}" -f $freeDisk
		Write-Host
		Write-Host $disk.PSComputerName " "$disk.DeviceID -ForegroundColor White -NoNewline
		Write-Host "  "-NoNewline
		Write-Host (" "*($usedSize * $thresold))-BackgroundColor Red -NoNewline
		Write-Host (" "*($freeDisk * $thresold)) -BackgroundColor Green -NoNewline
		#Write-Host $freeDisk "GB" -NoNewline
		Write-Host " " $percentDisk "Free"
		}
	Write-Host
	Write-Host $lines"Graph"$lines -ForegroundColor Cyan
	Write-Host 
	} 
