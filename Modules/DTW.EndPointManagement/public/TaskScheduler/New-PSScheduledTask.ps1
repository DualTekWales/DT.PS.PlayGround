function New-PSScheduledTask {
<#
    .SYNOPSIS
    Create a scheduled task.
    .DESCRIPTION
    Create a scheduled task.
    .PARAMETER TaskName
    Name of the task to create in task scheduler
    .PARAMETER TaskFolder
    
    .PARAMETER TaskDescription

    .PARAMETER TaskFrequency

    .PARAMETER TaskDaysOfWeek

    .PARAMETER TaskUser

    .PARAMETER TaskPassword

    .PARAMETER TaskLoginType

    .PARAMETER TaskScript

    .PARAMETER TaskRunPath

    .PARAMETER PowershellArgs

    .PARAMETER TaskScriptArgs

    .PARAMETER TaskStartTime

    .NOTES
    Created:    01/01/2024
    Version:	1.0.1
    Author:     Mark White
    Updated:    
    History:    1.0.1 -	Initial release

#>
    [CmdLetBinding()]
    param(
        [Parameter(Position=0, HelpMessage='Task name. If not set a random GUID will be used for the task name.')]
        [string]$TaskName,
        [Parameter(Position=1, HelpMessage='Task folder (in task manager).')]
        [string]$TaskFolder = '\',
        [Parameter(Position=2, HelpMessage='Task description.')]
        [string]$TaskDescription,
        [Parameter(Position=3, HelpMessage='Task frequency (2 = daily, 3 = weekly).')]
        [int]$TaskFrequency = 2,
        [Parameter(Position=4, HelpMessage='Task days to run if freqency is set to weekly.')]
        [int]$TaskDaysOfWeek = 0,
        [Parameter(Position=5, HelpMessage='User to run the task as. If not set then it will run as the current logged in user.')]
        [string]$TaskUser,
        [Parameter(Position=6, HelpMessage='Password of user running the task.')]
        [string]$TaskPassword,
        [Parameter(Position=7, HelpMessage='Task login type. Should be TASK_LOGON_PASSWORD if you are passing credentials. Otherwise defaults to TASK_LOGON_SERVICE_ACCOUNT.')]
        [ValidateSet('TASK_LOGON_NONE','TASK_LOGON_PASSWORD','TASK_LOGON_INTERACTIVE_TOKEN','TASK_LOGON_SERVICE_ACCOUNT')]
        [string]$TaskLoginType = 'TASK_LOGON_SERVICE_ACCOUNT',
        [Parameter(Position=8, HelpMessage='Task script.')]
        [string]$TaskScript,
        [Parameter(Position=8, HelpMessage='Path to run the scheduled task within.')]
        [string]$TaskRunPath,
        [Parameter(Position=9, HelpMessage='Powershell arguments.')]
        [string]$PowershellArgs = '-WindowStyle Hidden -NonInteractive -Executionpolicy unrestricted',
        [Parameter(Position=10, HelpMessage='Task Script Arguments.')]
        [string]$TaskScriptArgs,
        [Parameter(Position=11, HelpMessage='Task Start Time (defaults to 3AM tonight).')]
        [datetime]$TaskStartTime = $(Get-Date "$(((Get-Date).AddDays(1)).ToShortDateString()) 3:00 AM")
    )
    begin {
        # The Task Action command
        $TaskCommand = "c:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"

        # The Task Action command argument
        $TaskArg = "$PowershellArgs `"& `'$TaskScript`' $TaskScriptArgs`""
        
        switch ($TaskLoginType) {
            'TASK_LOGON_NONE' { $_TaskLoginType = 0 }
            'TASK_LOGON_PASSWORD' { $_TaskLoginType = 1 }
            'TASK_LOGON_INTERACTIVE_TOKEN' { $_TaskLoginType = 3 }
            default { $_TaskLoginType = 5 }
        }
 
    }
    process {}
    end {
        try {
            # attach the Task Scheduler com object
            $service = new-object -ComObject('Schedule.Service')
            # connect to the local machine. 
            # http://msdn.microsoft.com/en-us/library/windows/desktop/aa381833(v=vs.85).aspx
            $service.Connect()
            $rootFolder = $service.GetFolder($TaskFolder)
             
            $TaskDefinition = $service.NewTask(0) 
            $TaskDefinition.RegistrationInfo.Description = "$TaskDescription"
            $TaskDefinition.Settings.Enabled = $true
            $TaskDefinition.Settings.AllowDemandStart = $true
             
            $triggers = $TaskDefinition.Triggers
            #http://msdn.microsoft.com/en-us/library/windows/desktop/aa383915(v=vs.85).aspx
            $trigger = $triggers.Create($TaskFrequency)
            $trigger.StartBoundary = $TaskStartTime.ToString("yyyy-MM-dd'T'HH:mm:ss")
            $trigger.Enabled = $true
            if ($TaskFrequency -eq 3) {
                $trigger.DaysOfWeek = [Int16]$TaskDaysOfWeek
            }
             
            # http://msdn.microsoft.com/en-us/library/windows/desktop/aa381841(v=vs.85).aspx
            $Action = $TaskDefinition.Actions.Create(0)
            $action.Path = "$TaskCommand"
            $action.Arguments = "$TaskArg"
            if ($TaskRunPath) {
                $Action.WorkingDirectory = $TaskRunPath
            }

            #http://msdn.microsoft.com/en-us/library/windows/desktop/aa381365(v=vs.85).aspx
            $null = $rootFolder.RegisterTaskDefinition("$TaskName",$TaskDefinition,6,$TaskUser,$TaskPassword,$_TaskLoginType)
        }
        catch {
            throw
        }
    }
}