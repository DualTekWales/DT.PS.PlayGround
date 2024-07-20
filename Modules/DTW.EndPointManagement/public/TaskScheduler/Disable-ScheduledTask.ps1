function Disable-ScheduledTask {
<#
    
    .SYNOPSIS
        Script to disable a scheduled tasks.
    
    .DESCRIPTION
        Script to disable a scheduled tasks.

    .NOTES
        This function is pulled directly from the real Microsoft Windows Admin Center

    .ROLE
        Administrators
    
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
    
    Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName
    
}
