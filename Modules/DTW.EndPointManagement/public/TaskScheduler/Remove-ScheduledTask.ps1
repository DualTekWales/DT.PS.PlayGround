function Remove-ScheduledTask {
<#
    .SYNOPSIS
    Delete a scheduled task
    .DESCRIPTION
    Delete a scheduled task
    .PARAMETER Name
    This parameter contains the name of the scheduled task that is to be deleted
    .EXAMPLE
    Remove-ScheduledTask -Name "GoogleUpdateTaskMachineCore"
    Deletes the scheduled task 'GoogleUpdateTaskMachineCore'
    .NOTES
	Created:    26/10/2023
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
#>
    [CmdletBinding()]
    Param( 
        [Parameter(Mandatory = $true, Position = 0)][String]$Name
    )

    begin {
        [string]$FunctionName = $PSCmdlet.MyInvocation.MyCommand.Name
        WriteLog "I" "START FUNCTION - $FunctionName" $LogFile
    }
 
    process {
        WriteLog "I" "Delete the scheduled task $Name" $LogFile
        try {
            $Schedule = New-Object -ComObject 'Schedule.Service'
        }
        catch {
            WriteLog "E" "An error occurred trying to create the Schedule.Service COM Object (error: $($Error[0]))!" $LogFile
            Exit 1
        }

        $Schedule.connect($env:ComputerName) 
        $AllFolders = GetAllScheduledTaskSubFolders

        foreach ($Folder in $AllFolders) {
            if (($Tasks = $Folder.GetTasks(1))) {
                foreach ($Task in $Tasks) {
                    $TaskName = $Task.Name
                    #WriteLog "I" "Task name (including folder): $($Folder.Name)\$($TaskName)" $LogFile
                    if ($TaskName -eq $Name) {
                        try {
                            $Folder.DeleteTask($TaskName, 0)
                            WriteLog "I" "The scheduled task $TaskName was deleted successfully" $LogFile
                        }
                        catch {
                            WriteLog "E" "An error occurred trying to delete the scheduled task $TaskName (error: $($Error[0]))!" $LogFile
                            Exit 1
                        }
                    }
                }
            }
        }
    }
 
    end {
        WriteLog "I" "END FUNCTION - $FunctionName" $LogFile
    }
}