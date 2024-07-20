function Remove-ScheduledTaskAction {
<#
    
    .SYNOPSIS
        Removes action from scheduled task actions.
    
    .DESCRIPTION
        Removes action from scheduled task actions.

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
    
    
    ######################################################
    #### Main script
    ######################################################
    
    $task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath
    $actionsArray =  @()
    
    $task.Actions| ForEach-Object {
        $matched = $true;  
      
        if( -not ([string]::IsNullOrEmpty($_.Arguments) -and [string]::IsNullOrEmpty($actionArguments)))
        {
            if ($_.Arguments -ne $actionArguments)
            {
                $matched = $false;
            }
        }
    
        $workingDirectoryMatched  = $true;
        if( -not ([string]::IsNullOrEmpty($_.WorkingDirectory) -and [string]::IsNullOrEmpty($workingDirectory)))
        {
            if ($_.WorkingDirectory -ne $workingDirectory)
            {
                $matched = $false;
            }
        }
    
        $executeMatched  = $true;
        if ($_.Execute -ne $actionExecute) 
        {
              $matched = $false;
        }
    
        if (-not ($matched))
        {
            $actionsArray += $_;
        }
    }
    
    
    Set-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $actionsArray
}
