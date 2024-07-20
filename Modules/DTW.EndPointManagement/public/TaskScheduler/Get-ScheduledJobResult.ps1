function Get-ScheduledJobResult {
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
    [cmdletbinding()]
    [OutputType("ScheduledJobResult")]
    [Alias("ljr")]

    Param(
        [Parameter(Position = 0)]
        [ValidateNotNullorEmpty()]
        [string]$Name = "*",
        [validatescript( { $_ -gt 0 })]
        [int]$Newest = 1,
        [switch]$All
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay)   BEGIN] Starting $($myinvocation.mycommand)"
    } #begin

    Process {
        #only show results for Enabled jobs
        Try {
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Getting scheduled jobs for $name"
            $jobs = Get-ScheduledJob -Name $name -ErrorAction Stop #-ErrorVariable ev
        }
        Catch {
            Write-Warning "$Name : $($_.exception.message)"
            # $ev.errorRecord.Exception
        }

        if ($jobs) {
            #filter unless asking for all jobs

            if ($All) {
                Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Getting all jobs"
            }
            else {
                Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Getting enabled jobs only"
                $jobs = $jobs | Where-Object Enabled
            }
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Processing $($jobs.count) found jobs"
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Getting newest $newest job results"

            $data = $jobs | ForEach-Object {
                #get job and select all properties to create a custom object
                Try {
                    Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Trying to get jobs for $($_.name)"
                    Get-Job -Name $_.name -Newest $Newest -ErrorAction stop | ForEach-Object {
                        [scheduledjobresult]::new($_)
                    }
                } #Try
                Catch {
                    Write-Warning $_.exception.message
                    Write-Warning "Scheduled job $($_.TargetObject) has not been run yet."
                }
            } #Foreach Scheduled Job

            #write a sorted result to the pipeline
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Here are your $($data.count) results"
            $data | Sort-Object -Property PSEndTime -Descending

        } #if $jobs
    } #process
    End {
        Write-Verbose "[$((Get-Date).TimeofDay)     END] Ending $($myinvocation.MyCommand)"
    } #end

} #end function