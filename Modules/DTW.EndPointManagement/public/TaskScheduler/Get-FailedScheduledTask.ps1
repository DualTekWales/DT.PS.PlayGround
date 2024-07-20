function Get-FailedScheduledTask {
    <#
    .SYNOPSIS
    Lists scheduled tasks that ended in failure.
    
    .DESCRIPTION
    Lists scheduled tasks that ended in failure.
    All or only user-created tasks on specified machines are checked,
    which were last run X days ago.
    Disabled and old tasks are automatically ignored unless otherwise specified.

    Requires admin rights to run on localhost!

    .PARAMETER computerName
    List of machines on which they have sched. check the bags 

    .PARAMETER justUserTasks
    A switch saying that only user-created tasks should be checked

    .PARAMETER justActive
    A switch saying that only enabled tasks that ended with an error max before lastRunBeforeDays days should be listed
    or they are set to repeat and start again in 24 hours

    .PARAMETER lastRunBeforeDays
    Counting back in the day when it could have been sched. task last run
    I limit how old tasks can be checked

    .PARAMETER sendEmail
    They seemed to send me an email with the errors found

    .PARAMETER to
    What address should the email be sent to?
    The default is aaa@bbb.cz
    
    .EXAMPLE
    Import-Module Scripts,Computers -ErrorAction Stop
    Get-FailedScheduledTask -computerName $servers -JustUserTasks -LastRunBeforeDays 1 -sendEmail

    It checks the user sched on machines from $servers. tasks run in the last 24 hours and if found
    some ended by mistake, send their list to admin@fi.muni.cz
    
    .NOTES
    Created:    26/10/2023
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release

    #>

    [cmdletbinding()]
    param (
        $computerName = @($env:COMPUTERNAME)
        ,
        [switch] $justUserTasks
        ,
        [int] $lastRunBeforeDays = 1
        ,
        [switch] $justActive
        ,
        [switch] $sendEmail
        ,
        [string] $to = 'email.user@emaildomain.tld'
    )

    begin {
        if (!(Get-Command Write-Log -ea SilentlyContinue)) {
            throw "Requires Write-Log function."
        }

        $Error.Clear()

        $ComputerName = {$ComputerName.tolower()}.invoke()

        Write-Log "I check failed scheduled tasks on: $($ComputerName -join ', ')"

        # check that it runs with admin rights
        if ($env:COMPUTERNAME -in $computerName -and !([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            throw "It does not run with admin rights, which is required if you run the localhost command"
        }
        
    }

    process {
        # I use schtasks like this especially so that the diacritics are not distorted (it happens with native commands launched via psremoting)
        $failedTasks = invoke-command2 -computername $computerName -ArgumentList $lastRunBeforeDays, $justUserTasks, $justActive {
            param($lastRunBeforeDays, $justUserTasks, $justActive)

            # auxiliary functions
            function ConvertTo-DateTime {
                [CmdletBinding()]
                param (
                    [Parameter(Mandatory = $true, Position = 0)]
                    [ValidateNotNullOrEmpty()]
                    [String] $date
                    , 
                    [Parameter(Mandatory = $false, Position = 1)]
                    [ValidateNotNullOrEmpty()]
                    [String[]] $format = ('d.M.yyyy', 'd.M.yyyy H:m', 'd.M.yyyy H:m:s')
                )

                $result = New-Object DateTime

                $convertible = [DateTime]::TryParseExact(
                    $Date,
                    $Format,
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    [System.Globalization.DateTimeStyles]::None,
                    [ref]$result)

                if ($convertible) {
                    $result
                } else {
                }
            }

            # I could use Get-ScheduledTask and Get-ScheduledTaskInfo, but I don't exist on older OSes
            # I start via Start-Job because the native commands in the remote session do not return the correct diacritics during the "classic" start
            $job = Start-Job ([ScriptBlock]::Create('schtasks.exe /query /s localhost /V /FO CSV'))
            $null = Wait-Job $job 
            $tasks = Receive-Job $job | ConvertFrom-Csv
            Remove-Job $job

            # I filter out duplicate records (each task is there as many times as it has a trigger)
            [System.Collections.ArrayList] $uniqueTask = @()
            $tasks | ForEach-Object {
                if ($_.taskname -notin $uniqueTask.taskname) {
                    $null = $uniqueTask.add($_)
                }
            }
            $tasks = $uniqueTask
            
            if ($justUserTasks) {
                $domainName = $env:userdomain # netbios domain name (ntfi)
                $computer = $env:COMPUTERNAME
                if (!$domainName -or $domainName -eq $computer) { $domainName = 'ntfi' }
                $tasks = $tasks | Where-Object {($_.author -like "$domainName\*" -or $_.author -like "$computer\*")}
            }

            # tasks that ended with an error at the last run
            # I ignore some unsaved result codes, because they are not real errors
            # 267009 = task is currently running 
            # 267014 = task task was terminated by user
            # 267011 = task has not yet run
            # -2147020576 = operator or administrator has refused the request
            # -2147216609 = an instance of this task is already running
            $tasks = $tasks | Where-Object {($_.'last Result' -ne 0 -and $_.'last Result' -notin (267009, 267014, 267011, -2147020576, -2147216609) -and $_.'last run time' -ne 'N/A')}

            #TODO this method of filtering does not catch problems with tasks that are created with the help of GPO in replacement mode, because with every gpupdate a replacement task occurs, i.e. you lose information
            # it could be solved by pulling the information from the event log, where the history per taskname is logged

            if ($justActive) {
                # return only enabled tasks that were started max $LastRunBeforeDays days ago
                # or I repeat myself and have to be started again within 24 hours
                $tasks = $tasks | Where-Object {
                    $_.'Scheduled Task State' -eq 'Enabled' `
                        -and (
                        ($(try {ConvertTo-DateTime $_.'last run time' -ea stop} catch {Get-Date 1.1.1999}) -gt [datetime]::now.AddDays( - $LastRunBeforeDays))`
                            -or 
                        ($_.'Repeat: Every' -ne "N/A" -and ($(try {ConvertTo-DateTime ($_.'Next Run Time') -ea stop} catch {Get-Date 1.1.9999}) -lt [datetime]::now.AddDays(1)))
                    )
                } 
            }

            # write the result
            $tasks | Select-Object taskname, 'last result', 'last run time', 'next run time', @{n = 'Computer'; e = {$env:COMPUTERNAME}}
        } -ErrorAction SilentlyContinue
    }

    end {
        if ($Error) {
            Write-Log -ErrorRecord $Error
        }

        if ($failedTasks) {
            Write-Log -Message $($failedTasks | Format-List taskname, 'last result', 'last run time', computer | Out-String) 

            $body = "Hello,`nBelow is a list of failed scheduled tasks for the past day:`n`n"
            $body += $failedTasks | Format-List taskname, 'last result', 'last run time', computer | Out-String
            $body += "`n`n`nCheck progress on: $($computerName -join ', ')" 

            if ($Error) {
                $body += "`n`n`n Errors appeared:`n$($Error | out-string)"        
            }
            
            if ($sendEmail) {
                Send-Email -Subject "Failnute scheduled tasks run for $LastRunBeforeDays in the last days" -Body $body -To $To
            }
        } else {
            if ($justActive) {
                $t = " (run from $([datetime]::now.AddDays( - $LastRunBeforeDays)))"
            }
            
            Write-Log "Failed to start sched. tasks $t not found
            "
        }
    }
}
