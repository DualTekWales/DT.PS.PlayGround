function Search-PSCommand {
<#
.DESCRIPTION

.NOTES
	Created:    26/10/2023
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
    
#>
[CmdletBinding()]
    param (
        [string]$Filter
    )

    Get-Command | Where-Object { $_.Name -like "*$Filter*" } | Sort-Object Name | Format-Table Name, Version, Source
}