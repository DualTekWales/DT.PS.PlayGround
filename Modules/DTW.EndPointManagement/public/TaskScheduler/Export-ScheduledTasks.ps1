﻿function Export-ScheduledTasks {
<#
.SYNOPSIS
Exports scheduled tasks as a PowerShell script that can be run to restore them.

.OUTPUTS
System.String containing a PowerShell script to create each task.

.LINK
Export-ScheduledTask

.EXAMPLE
Export-ScheduledTasks.ps1 |Out-File Import-ScheduledTasks.ps1 utf8

Exports all scheduled tasks as PowerShell Register-ScheduledJob cmdlet strings.

.NOTES
	Created:    26/10/2023
    Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
    
#>

[CmdletBinding()][OutputType([string])] Param(
# Specifies the task path to export from.
[Parameter(Position=0)][string]$TaskPath = '\'
)

function Export-ScheduledTaskAsXml
{
[CmdletBinding()] Param(
[Parameter(Position=0,ValueFromPipeline=$true)][Microsoft.Management.Infrastructure.CimInstance]$Task
)
Process
{@"
@{
    TaskName = $($Task.TaskName |ConvertTo-PowerShell.ps1)
    Xml      = @'
$((Export-ScheduledTask $Task.TaskName $Task.TaskPath) -replace "(?m)^'@$",'&#39;@')
'@
} |% {Register-ScheduledTask @_}
"@}
}

Get-ScheduledTask -TaskPath $TaskPath |Export-ScheduledTaskAsXml
}