function Add-ScheduledTaskAction {
<#
    
    .SYNOPSIS
        Adds a new action to existing scheduled task actions.
    
    .DESCRIPTION
        Adds a new action to existing scheduled task actions.

    .NOTES
        This function is pulled directly from the real Microsoft Windows Admin Center
        
    .ROLE
        Administrators
    
    .PARAMETER taskName
        The name of the task
    
    .PARAMETER taskPath
        The task path.
    
    .PARAMETER actionExecute
        The name of executable to run. By default looks in System32 if Working Directory is not provided
    
    .PARAMETER actionArguments
        The arguments for the executable.
    
    .PARAMETER workingDirectory
        The path to working directory
    
    .NOTES
        Created:    01/01/2024
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release
        
#>
    param (
        [parameter(Mandatory=$true)]
        [string]
        $taskName,
        [parameter(Mandatory=$true)]
        [string]
        $taskPath,
        [parameter(Mandatory=$true)]
        [string]
        $actionExecute,
        [string]
        $actionArguments,
        [string]
        $workingDirectory  
    )
    
    Import-Module ScheduledTasks
    
    #
    # Prepare action parameter bag
    #
    $taskActionParams = @{
        Execute = $actionExecute;
    } 
    
    if ($actionArguments) {
        $taskActionParams.Argument = $actionArguments;
    }
    if ($workingDirectory) {
         $taskActionParams.WorkingDirectory = $workingDirectory;
    }
    
    ######################################################
    #### Main script
    ######################################################
    
    # Create action object
    $action = New-ScheduledTaskAction @taskActionParams
    
    $task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath
    $actionsArray =  $task.Actions
    $actionsArray += $action 
    Set-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $actionsArray
}
