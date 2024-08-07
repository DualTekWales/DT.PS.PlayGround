function Add-TaskTrigger {
<#
.Synopsis
    Adds a trigger to an existing task.
.Description
    Adds a trigger to an existing task.
    The task is outputted to the pipeline, so that additional triggers can be added.
.Example
    New-task | 
        Add-TaskTrigger -DayOfWeek Monday, Wednesday, Friday -WeeksInterval 2 -At "3:00 PM" |
        Add-TaskAction -Script { Get-Process | Out-GridView } |
        Register-ScheduledTask TestTask    
.Link
    Add-TaskAction
.Link
    Register-ScheduledTask
.Link
    New-Task
.NOTES
    Created:    01/01/2024
    Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
    
#>
    [CmdletBinding(DefaultParameterSetName="OneTime")]
    param(
    # The Scheduled Task Definition.  A New definition can be created by using New-Task
    [Parameter(Mandatory=$true, 
        ValueFromPipeline=$true)]
    [Alias('Definition')]
    [__ComObject]
    $Task,
    
    # The At parameter is used as the start time of the task for several different trigger types.
    [Parameter(Mandatory=$true,ParameterSetName="Daily")]        
    [Parameter(Mandatory=$true,ParameterSetName="DayInterval")]    
    [Parameter(Mandatory=$true,ParameterSetName="Monthly")]
    [Parameter(Mandatory=$true,ParameterSetName="MonthlyDayOfWeek")]
    [Parameter(Mandatory=$true,ParameterSetName="OneTime")]    
    [Parameter(Mandatory=$true,ParameterSetName="Weekly")]
    [DateTime]
    $At,
    
    # Day of Week Trigger
    [Parameter(Mandatory=$true, ParameterSetName="Weekly")]
    [Parameter(Mandatory=$true, ParameterSetName="MonthlyDayOfWeek")]
    [ValidateSet("Sunday","Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")]
    [string[]]
    $DayOfWeek,
    
    # If set, will only run the task N number of weeks
    [Parameter(ParameterSetName="Weekly")]
    [Int]
    $WeeksInterval = 1,
    
    # Months of Year
    [Parameter(Mandatory=$true, ParameterSetName="Monthly")]
    [Parameter(Mandatory=$true, ParameterSetName="MonthlyDayOfWeek")]
    [ValidateSet("January","February", "March", "April", "May", "June", 
        "July", "August", "September","October", "November", "December")]
    [string[]]
    $MonthOfYear,
    
    # The day of the month to run the task on
    [Parameter(Mandatory=$true, ParameterSetName="Monthly")]
    [ValidateRange(1,31)]
    [int[]]
    $DayOfMonth,
    
    # The weeks of the month to run the task on.  
    [Parameter(Mandatory=$true, ParameterSetName="MonthlyDayOfWeek")]    
    [ValidateRange(1,6)]
    [int[]]
    $WeekOfMonth,
    
    # The timespan to run the task in.
    [Parameter(Mandatory=$true,ParameterSetName="In")]
    [Timespan]
    $In,
        
    # If set, the task will trigger at a specific time every day
    [Parameter(ParameterSetName="Daily")]
    [Switch]
    $Daily,

    # If set, the task will trigger every N days
    [Parameter(ParameterSetName="DaysInterval")]    
    [Int]
    $DaysInterval,             
    
    # If set, a registration trigger will be created
    [Parameter(Mandatory=$true,ParameterSetName="Registration")]
    [Switch]
    $OnRegistration,
    
    # If set, the task will be triggered on boot
    [Parameter(Mandatory=$true,ParameterSetName="Boot")]
    [Switch]
    $OnBoot,
    
    # If set, the task will be triggered on logon.
    # Use the OfUser parameter to only trigger the task for certain users
    [Parameter(Mandatory=$true,ParameterSetName="Logon")]
    [Switch]
    $OnLogon,
    
    # In Session State tasks or logon tasks, determines what type of users will launch the task
    [Parameter(ParameterSetName="Logon")]
    [Parameter(ParameterSetName="StateChanged")]
    [string]
    $OfUser,
    
    # In Session State triggers, this parameter is used to determine what state change will trigger the task
    [Parameter(Mandatory=$true,ParameterSetName="StateChanged")]
    [ValidateSet("Connect", "Disconnect", "RemoteConnect", "RemoteDisconnect", "Lock", "Unlock")]
    [string]
    $OnStateChanged,
    
    # If set, the task will be triggered on Idle
    [Parameter(Mandatory=$true,ParameterSetName="Idle")]
    [Switch]
    $OnIdle,
    
    # If set, the task will be triggered whenever the event occurs.  To get an event record, use Get-WinEvent
    [Parameter(Mandatory=$true, ParameterSetName="Event")]
    [Diagnostics.Eventing.Reader.EventLogRecord]
    $OnEvent,
    
    # If set, the task will be triggered whenever the event query occurs.  The query is in xpath.
    [Parameter(Mandatory=$true, ParameterSetName="EventQuery")]
    [string]
    $OnEventQuery,

    # The interval the task should be repeated at.
    [Timespan]
    $Repeat,
    
    # The amount of time to repeat the task for
    [Timespan]
    $For,
    
    # The time the task should stop being valid
    [DateTime]
    $Until    
    )
    
    begin {
        Set-StrictMode -Off
    }
    process {
        if ($Task.Definition) {  $Task = $Task.Definition }
        
        switch ($psCmdlet.ParameterSetName) {
            StateChanged {
                $Trigger = $Task.Triggers.Create(11)
                if ($OfUser) {
                    $Trigger.UserID = $OfUser
                }
                switch ($OnStateChanged) {
                    Connect { $Trigger.StateChange = 1 }
                    Disconnect { $Trigger.StateChange = 2 }
                    RemoteConnect { $Trigger.StateChange = 3 }
                    RemoteDisconnect { $Trigger.StateChange = 4 }
                    Lock { $Trigger.StateChange = 7 }
                    Unlock { $Trigger.StateChange = 8 } 
                }
            }
            Logon {
                $Trigger = $Task.Triggers.Create(9)
                if ($OfUser) {
                    $Trigger.UserID = $OfUser
                }
            }
            Boot {
                $Trigger = $Task.Triggers.Create(8)
            }
            Registration {
                $Trigger = $Task.Triggers.Create(7)
            }
            OneTime {
                $Trigger = $Task.Triggers.Create(1)
                $Trigger.StartBoundary = $at.ToString("s")
            }            
            Daily {
                $Trigger = $Task.Triggers.Create(2)
                $Trigger.StartBoundary = $at.ToString("s")
                $Trigger.DaysInterval = 1
            }
            DaysInterval {
                $Trigger = $Task.Triggers.Create(2)
                $Trigger.StartBoundary = $at.ToString("s")
                $Trigger.DaysInterval = $DaysInterval                
            }
            Idle {
                $Trigger = $Task.Triggers.Create(6)
            }
            Monthly {
                $Trigger =  $Task.Triggers.Create(4)
                $Trigger.StartBoundary = $at.ToString("s")
                $value = 0
                foreach ($month in $MonthOfYear) {
                    switch ($month) {
                        January { $value = $value -bor 1 }
                        February { $value = $value -bor 2 }
                        March { $value = $value -bor 4 }
                        April { $value = $value -bor 8 }
                        May { $value = $value -bor 16 }
                        June { $value = $value -bor 32 }
                        July { $value = $value -bor 64 }
                        August { $value = $value -bor 128 }
                        September { $value = $value -bor 256 }
                        October { $value = $value -bor 512 } 
                        November { $value = $value -bor 1024 } 
                        December { $value = $value -bor 2048 } 
                    } 
                }
                $Trigger.MonthsOfYear = $Value
                $value = 0
                foreach ($day in $DayofMonth) {
                    $value = $value -bor ([Math]::Pow(2, $day - 1))
                }
                $Trigger.DaysOfMonth  = $value
            }
            MonthlyDayOfWeek {
                $Trigger =  $Task.Triggers.Create(5)
                $Trigger.StartBoundary = $at.ToString("s")
                $value = 0
                foreach ($month in $MonthOfYear) {
                    switch ($month) {
                        January { $value = $value -bor 1 }
                        February { $value = $value -bor 2 }
                        March { $value = $value -bor 4 }
                        April { $value = $value -bor 8 }
                        May { $value = $value -bor 16 }
                        June { $value = $value -bor 32 }
                        July { $value = $value -bor 64 }
                        August { $value = $value -bor 128 }
                        September { $value = $value -bor 256 }
                        October { $value = $value -bor 512 } 
                        November { $value = $value -bor 1024 } 
                        December { $value = $value -bor 2048 } 
                    } 
                }
                $Trigger.MonthsOfYear = $Value
                $value = 0
                foreach ($week in $WeekofMonth) {
                    $value = $value -bor ([Math]::Pow(2, $week - 1))
                }
                $Trigger.WeeksOfMonth = $value            
                $value = 0
                foreach ($day in $DayOfWeek) {
                    switch ($day) {
                        Sunday { $value = $value -bor 1 }
                        Monday { $value = $value -bor 2 }
                        Tuesday { $value = $value -bor 4 }
                        Wednesday { $value = $value -bor 8 }
                        Thursday { $value = $value -bor 16 }
                        Friday { $value = $value -bor 32 }
                        Saturday { $value = $value -bor 64 }
                    }   
                }
                $Trigger.DaysOfWeek = $value

            }
            Weekly {
                $Trigger = $Task.Triggers.Create(3)
                $Trigger.StartBoundary = $at.ToString("s")
                $value = 0
                foreach ($day in $DayOfWeek) {
                    switch ($day) {
                        Sunday { $value = $value -bor 1 }
                        Monday { $value = $value -bor 2 }
                        Tuesday { $value = $value -bor 4 }
                        Wednesday { $value = $value -bor 8 }
                        Thursday { $value = $value -bor 16 }
                        Friday { $value = $value -bor 32 }
                        Saturday { $value = $value -bor 64 }
                    }   
                }
                $Trigger.DaysOfWeek = $value
                $Trigger.WeeksInterval = $WeeksInterval
            }
            In {
                $Trigger = $Task.Triggers.Create(1)
                $at = (Get-Date) + $in
                $Trigger.StartBoundary = $at.ToString("s")
            }
            Event {
                $Query = $Task.Triggers.Create(0)
                $Query.Subscription = "
<QueryList>
    <Query Id='0' Path='$($OnEvent.LogName)'>
        <Select Path='$($OnEvent.LogName)'>
            *[System[Provider[@Name='$($OnEvent.ProviderName)'] and EventID=$($OnEvent.Id)]]
        </Select>
    </Query>
</QueryList>                
                "
            }
            EventQuery {
                $Query = $Task.Triggers.Create(0)
                $Query.Subscription = $OnEventQuery
            }
        }
        if ($Until) {
            $Trigger.EndBoundary = $until.ToString("s")
        }
        if ($Repeat.TotalSeconds) {
            $Trigger.Repetition.Interval = "PT$([Math]::Floor($Repeat.TotalHours))H$($Repeat.Minutes)M"
        }
        if ($For.TotalSeconds) {
            $Trigger.Repetition.Duration = "PT$([Math]::Floor($For.TotalHours))H$([int]$For.Minutes)M$($For.Seconds)S"
        }
        $Task
    }
}