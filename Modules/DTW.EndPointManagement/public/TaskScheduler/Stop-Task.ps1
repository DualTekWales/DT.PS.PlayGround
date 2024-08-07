function Stop-Task {
    <#
    .Synopsis
        Stops a scheduled task
    .Description
        Stops a scheduled task or a running task.  Scheduled tasks can be supplied with Get-Task and 
        
    .Example
        # Note, this is an example of the syntax.  You should never stop all running tasks, 
        # as they are used by the operating system.  Instead, use a filter to get the tasks
        Get-RunningTask | Stop-Task
    .NOTES
        Created:    01/01/2024
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release
        
    #>
    [CmdletBinding()]
    param(
    # The Task to stop.  The task can either be from the result of Get-ScheduledTask or Get-RunningTask
    [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
    [__ComObject]
    $Task
    )
    
    process {
        if ($Task.PSObject.TypeNames -contains 'System.__ComObject#{9c86f320-dee3-4dd1-b972-a303f26b061e}') {
            $Task.Stop(0)
        } else {
            $Task.Stop()
        }
    }
}