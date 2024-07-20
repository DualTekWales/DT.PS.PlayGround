Function Get-ScheduledJobDetail {
<#
	.SYNOPSIS
	
	.DESCRIPTION
	
	.EXAMPLE
	
	.NOTES
        Created:    26/10/2023
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release
#>
	[CmdletBinding(DefaultParameterSetName = "name")]
    [OutputType("ScheduledJobDetail")]

    Param(
        [Parameter(Position = 0, ValueFromPipeline, Mandatory, ParameterSetName = "name")]
        [ValidateNotNullorEmpty()]
        [string[]]$Name,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "job")]
        [ValidateNotNullorEmpty()]
        [alias("job")]
        [Microsoft.PowerShell.ScheduledJob.ScheduledJobDefinition]$ScheduledJob
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay)   BEGIN] Starting $($myinvocation.mycommand)"
    } #begin

    Process {

        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Using parameter set $($pscmdlet.ParameterSetName)"
        $jobs = @()
        if ($PSCmdlet.ParameterSetName -eq 'name') {
            foreach ($item in $name) {
                Try {
                    Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Getting scheduledjob $item"
                    $jobs += Get-ScheduledJob -Name $item -ErrorAction Stop
                }
                Catch {
                    Write-Warning $_.exception.message
                }
            }
        } #if Name
        else {
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Using scheduledjob $($scheduledjob.name)"
            $jobs += $ScheduledJob
        }

        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Getting scheduledjob details"
        foreach ($job in $jobs) {
            #get corresponding task
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] $($job.name)"
            $task = Get-ScheduledTask -TaskName $job.name
            $info = $task | Get-ScheduledTaskInfo
            [pscustomobject]@{
                PSTypeName             = "ScheduledJobDetail"
                ID                     = $job.ID
                Name                   = $job.name
                Command                = $job.command
                Enabled                = $job.enabled
                State                  = $task.State
                NextRun                = $info.nextRunTime
                MaxHistory             = $job.ExecutionHistoryLength
                RunAs                  = $task.Principal.UserID
                Frequency              = $job.JobTriggers.Frequency
                Days                   = $job.JobTriggers.DaysOfWeek
                RepetitionDuration     = $job.JobTriggers.RepetitionDuration
                RepetitionInterval     = $job.JobTriggers.RepetitionInterval
                DoNotAllowDemandStart  = $job.options.DoNotAllowDemandStart
                IdleDuration           = $job.options.IdleDuration
                IdleTimeout            = $job.options.IdleTimeout
                MultipleInstancePolicy = $job.options.MultipleInstancePolicy
                RestartOnIdleResume    = $job.options.RestartOnIdleResume
                RunElevated            = $job.options.RunElevated
                RunWithoutNetwork      = $job.options.RunWithoutNetwork
                ShowInTaskScheduler    = $job.options.ShowInTaskScheduler
                StartIfNotIdle         = $job.options.StartIfNotIdle
                StartIfOnBatteries     = $job.options.StartIfOnBatteries
                StopIfGoingOffIdle     = $job.options.StopIfGoingOffIdle
                StopIfGoingOnBatteries = $job.options.StopIfGoingOnBatteries
                WakeToRun              = $job.options.WakeToRun
            }

        } #foreach job

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay)     END] Ending $($myinvocation.MyCommand)"
    } #end
}