function New-ScheduledTask {
    <#
    .Synopsis
        Creates a new task definition.
    .Description
        Creates a new task definition.
        Tasks are not scheduled until Register-ScheduledTask is run.
        To add triggers use Add-TaskTrigger.  
        To add actions, use Add-TaskActions
    .Link
        Add-TaskTrigger
        Add-TaskActions
        Register-ScheduledTask
    .Example
        An example of using the command
    .NOTES
        Created:    01/01/2024
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release

    #>
    [CmdletBinding()]
    param(
    # The name of the computer to connect to.
    $ComputerName,
    
    # The credential used to connect
    [Management.Automation.PSCredential]
    $Credential,
    
    # If set, the task will wake the computer to run
    [Switch]
    $WakeToRun,
    
    # If set, the task will run on batteries and will not stop when going on batteries
    [Switch]
    $RunOnBattery,
    
    # If set, the task will run only if connected to the network
    [Switch]
    $RunOnlyIfNetworkAvailable,
    
    # If set, the task will run only if the computer is idle
    [Switch]
    $RunOnlyIfIdle,
    
    # If set, the task will run after its scheduled time as soon as it is possible
    [Switch]
    $StartWhenAvailable,
    
    # The maximum amount of time the task should run
    [Timespan]
    $ExecutionTimeLimit = (New-TimeSpan),
    
    # Sets how the task should behave when an existing instance of the task is running.
    # By default, a 2nd instance of the task will not be started
    [ValidateSet("Parallel", "Queue", "IgnoreNew", "StopExisting")]
    [String]
    $MultipleInstancePolicy = "IgnoreNew",

    # The priority of the running task    
    [ValidateRange(1, 10)]
    [int]
    $Priority = 6,
    
    # If set, the new task will be a hidden task
    [Switch]
    $Hidden,
    
    # If set, the task will be disabled 
    [Switch]
    $Disabled,
    
    # If set, the task will not be able to be started on demand
    [Switch]
    $DoNotStartOnDemand,
    
    # If Set, the task will not be able to be manually stopped
    [Switch]
    $DoNotAllowStop
    )
        
    $scheduler = Connect-ToTaskScheduler -ComputerName $ComputerName -Credential $Credential            
    $task = $scheduler.NewTask(0)
    $task.Settings.Priority = $Priority
    $task.Settings.WakeToRun = $WakeToRun
    $task.Settings.RunOnlyIfNetworkAvailable = $RunOnlyIfNetworkAvailable
    $task.Settings.StartWhenAvailable = $StartWhenAvailable
    $task.Settings.Hidden = $Hidden
    $task.Settings.RunOnlyIfIdle = $RunOnlyIfIdle
    $task.Settings.Enabled = -not $Disabled
    if ($RunOnBattery) {
        $task.Settings.StopIfGoingOnBatteries = $false
        $task.Settings.DisallowStartIfOnBatteries = $false
    }
    $task.Settings.AllowDemandStart = -not $DoNotStartOnDemand
    $task.Settings.AllowHardTerminate = -not $DoNotAllowStop
    switch ($MultipleInstancePolicy) {
        Parallel { $task.Settings.MultipleInstances = 0 }
        Queue { $task.Settings.MultipleInstances = 1 }
        IgnoreNew { $task.Settings.MultipleInstances = 2}
        StopExisting { $task.Settings.MultipleInstances = 3 } 
    }
    $task
}