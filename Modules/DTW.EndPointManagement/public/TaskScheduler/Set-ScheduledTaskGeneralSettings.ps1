function Set-ScheduledTaskGeneralSettings {
<#
    
    .SYNOPSIS
        Creates and registers a new scheduled task.
    
    .DESCRIPTION
        Creates and registers a new scheduled task.

    .ROLE
        Administrators
    
    .PARAMETER taskName
        The name of the task
    
    .PARAMETER taskDescription
        The description of the task.
    
    .PARAMETER taskPath
        The task path.
    
    .PARAMETER username
        The username to use to run the task.
    
    .NOTES
        Created:    26/10/2023
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release
        
#>
[CmdletBinding()]
    param (
        [parameter(Mandatory=$true)]
        [string]
        $taskName,
        [string]
        $taskDescription,
        [parameter(Mandatory=$true)]
        [string]
        $taskPath,
        [string]
        $username
    )
    
    Import-Module ScheduledTasks
    
    ######################################################
    #### Main script
    ######################################################
    
    $task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath
    if($task) {
        
        $task.Description = $taskDescription;
      
        if ($username)
        {
            $task | Set-ScheduledTask -User $username ;
        } 
        else 
        {
            $task | Set-ScheduledTask
        }
    }
}
