function Stop-ScheduledTask {
<#
    
    .SYNOPSIS
        Script to stop a scheduled tasks.
    
    .DESCRIPTION
        Script to stop a scheduled tasks.

    .ROLE
        Administrators
    
    .NOTES
        Created:    26/10/2023
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release
        
#>
[CmdletBinding()]
    param (
      [Parameter(Mandatory = $true)]
      [String]
      $taskPath,
    
      [Parameter(Mandatory = $true)]
      [String]
      $taskName
    )
    
    Import-Module ScheduledTasks
    
    Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName | ScheduledTasks\Stop-ScheduledTask
}
