function Get-ScheduledTask {
    <#
    .Synopsis
        Gets tasks scheduled on the computer
    .Description
        Gets scheduled tasks that are registered on a computer
    .Example
        Get-ScheduleTask -Recurse
    .NOTES
        Created:    01/01/2024
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release
    #>
    [CmdletBinding()]
    param(
    # The name or name pattern of the scheduled task
    [Parameter()]
    $Name = "*",
    
    # The folder the scheduled task is in
    [Parameter()]
    [String[]]
    $Folder = "",
    
    # If this is set, hidden tasks will also be shown.  
    # By default, only tasks that are not marked by Task Scheduler as hidden are shown.
    [Switch]
    $Hidden,    
    
    # The name of the computer to connect to.
    $ComputerName,
    
    # The credential used to connect
    [Management.Automation.PSCredential]
    $Credential,
    
    # If set, will get tasks recursively beneath the specified folder
    [switch]
    $Recurse
    )
    
    process {
        $scheduler = Connect-ToTaskScheduler -ComputerName $ComputerName -Credential $Credential            
        $taskFolder = $scheduler.GetFolder($folder)
        $taskFolder.GetTasks($Hidden -as [bool]) | Where-Object {
            $_.Name -like $name
        }
        if ($Recurse) {
            $taskFolder.GetFolders(0) | ForEach-Object {
                $psBoundParameters.Folder = $_.Path
                Get-ScheduledTask @psBoundParameters
            }
        }        
    }
} 
