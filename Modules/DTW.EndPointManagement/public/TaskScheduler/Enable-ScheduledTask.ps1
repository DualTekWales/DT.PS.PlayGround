function Enable-ScheduledTask {
<#
    
    .SYNOPSIS
        Script to enable a scheduled tasks.
    
    .DESCRIPTION
        Script to enable a scheduled tasks.

    .ROLE
        Administrators
    
    .NOTES
        Created:    01/01/2024
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release
        
#>
    param (
      [Parameter(Mandatory = $true)]
      [String]
      $taskPath,
    
      [Parameter(Mandatory = $true)]
      [String]
      $taskName
    )
    
    Import-Module ScheduledTasks
    
    Enable-ScheduledTask -TaskPath $taskPath -TaskName $taskName
    
}
