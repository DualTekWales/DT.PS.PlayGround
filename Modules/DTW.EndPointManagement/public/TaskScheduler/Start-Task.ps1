function Start-Task {
    <#
    .Synopsis
        Starts a scheduled task
    .Description
        Starts running a scheduled task.
        The input to the command is the output of Get-ScheduledTask.
    .Example
        New-Task | 
            Add-TaskAction -Script { 
                Get-Process | Out-GridView
                Start-Sleep 100
            } | 
            Register-ScheduledTask (Get-Random) |
            Start-Task
    .NOTES
        Created:    01/01/2024
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release

    #>
    [CmdletBinding()]
    param(
    # The Task to start.  To get tasks, use Get-ScheduledTask 
    [Parameter(ValueFromPipeline=$true,
        Mandatory=$true)]
    [__ComObject]
    $Task
    )
    
    process {
        $Task.Run(0)
    }
}