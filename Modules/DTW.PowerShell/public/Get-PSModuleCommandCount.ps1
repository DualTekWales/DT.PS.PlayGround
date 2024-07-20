function Get-PSModuleCommandCount {
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
            HelpMessage = "Enter the name of the module. It must be one that is imported.",
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Module')]
        [string]$ModuleName,

        [switch]$Functions
    )

    if ($Functions) { (Get-Command -Module $ModuleName -CommandType Function).Count }
    else { (Get-Command -Module $ModuleName).Count }
}