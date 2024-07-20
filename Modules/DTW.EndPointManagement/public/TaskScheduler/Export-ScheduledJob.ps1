Function Export-ScheduledJob {
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
    [cmdletbinding(SupportsShouldProcess, DefaultParameterSetName = "name")]
    [OutputType("None", "System.IO.FileInfo")]
    [Alias("esj")]

    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = "name")]
        [ValidateNotNullorEmpty()]
        [string]$Name,

        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = "job")]
        [ValidateNotNullorEmpty()]
        [alias("job")]
        [Microsoft.PowerShell.ScheduledJob.ScheduledJobDefinition]$ScheduledJob,

        [ValidateScript( {
                if (-Not (Test-Path -path $_)) {
                    Throw "Could not verify the path."
                }
                else {
                    $True
                }
            })]
        [ValidateScript( { Test-Path $_ })]
        [string]$Path = (Get-Location).Path,
        [switch]$Passthru
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay)   BEGIN] Starting $($myinvocation.mycommand)"
    } #begin

    Process {

        if ($Name) {
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Getting scheduled job $job"
            Try {
                $ExportJob = Get-ScheduledJob -Name $name -ErrorAction Stop
            }
            Catch {
                Write-Warning "Failed to get scheduled job $name"
                #bail out
                Return
            }
        } #if
        else {
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Using scheduled job $($scheduledjob.name)"
            $ExportJob = $scheduledjob
        }

        $ExportPath = Join-Path -Path $path -ChildPath "$($ExportJob.Name).xml"
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Starting the export process of $($ExportJob.Name) to $ExportPath"

        $ExportJob | Select-Object -property Name,
        @{Name         = "Scriptblock";
            Expression = {
                ($_.InvocationInfo.Parameters.Item(0) |
                        Where-Object { $_.name -eq "ScriptBlock" }).value
            }
        },
        @{Name         = "FilePath";
            Expression = {
                ($_.InvocationInfo.Parameters.Item(0) |
                        Where-Object { $_.name -eq "FilePath" }).value
            }
        },
        @{Name         = "ArgumentList";
            Expression = {
                ($_.InvocationInfo.Parameters.Item(0) |
                        Where-Object { $_.name -eq "ArgumentList" }).value
            }
        },
        @{Name         = "Authentication";
            Expression = {
                ($_.InvocationInfo.Parameters.Item(0) |
                        Where-Object { $_.name -eq "Authentication" }).value
            }
        },
        @{Name         = "InitializationScript";
            Expression = {
                ($_.InvocationInfo.Parameters.Item(0) |
                        Where-Object { $_.name -eq "InitializationScript" }).value
            }
        },
        @{Name         = "RunAs32";
            Expression = {
                ($_.InvocationInfo.Parameters.Item(0) |
                        Where-Object { $_.name -eq "RunAs32" }).value
            }
        },
        @{Name         = "Credential";
            Expression = {
                $_.Credential.UserName
            }
        },
        @{Name         = "Options";
            Expression = {
                #don't export the job definition here
                $_.Options | Select-Object -property * -ExcludeProperty JobDefinition
            }
        },
        @{Name         = "JobTriggers";
            Expression = {
                #don't export the job definition here
                $_.JobTriggers | Select-Object -property * -ExcludeProperty JobDefinition
            }
        }, ExecutionHistoryLength, Enabled |
        Export-Clixml -Path $ExportPath

    if ($Passthru) {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Writing the export file item to the pipeline"
        Get-Item -Path $ExportPath
    }

    Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Export finished."
} #process

End {
    Write-Verbose "[$((Get-Date).TimeofDay)     END] Ending $($myinvocation.MyCommand)"
} #end
} #end Export-ScheduledJob