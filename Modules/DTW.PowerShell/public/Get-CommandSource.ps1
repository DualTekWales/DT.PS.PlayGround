Function Get-CommandSource {
<#
    .SYNOPSIS
        Get command source.
    .NOTES
        Created:    26/10/2023
        Author:     Mark White
        Version:    0.0.2
        Updated:    14/11/2023
        History:    0.0.1 - Initial release
	                0.0.2 - Updated function to include name & source upon export
    .INPUTS
        System.String
    .OUTPUTS
        System.String
		System.Switch
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string]$CommandName,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [switch]$All
    )
    if ($All) {
        Get-Command -Name $CommandName -All | Select-Object -Property Name, Source
    }
    else {
        (Get-Command -Name $CommandName).ModuleName
    }
}