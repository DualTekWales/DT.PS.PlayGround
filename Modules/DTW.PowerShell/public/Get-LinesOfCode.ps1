function Get-LinesOfCode {
    <#
.NOTES
    Created:    01/01/2024
    Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
    
#>
    [CmdletBinding()]
    param(
        [Parameter(
            HelpMessage = "Enter the path of the folder you want to count lines of PowerShell and JSON code for",
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    (Get-ChildItem -Path $Path -Recurse | Where-Object { $_.extension -in '.ps1', '.psm1', '.psd1', '.json' } | select-string "^\s*$" -notMatch).Count
}