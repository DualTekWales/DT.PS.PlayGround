function Start-SysMScheduleTask {
<#
.SYNOPSIS
    Starts a scheduled task

.DESCRIPTION

.NOTES
	Created:    26/10/2023
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release

.Parameter TaskName
    Specifies the name of a scheduled task

.Parameter ComputerName
    Specifies the name of the computer on which to start the schedule task
    
.Parameter AccessAccount
    Specifies a user account that has permission to perform this action. If Credential is not specified, the current user account is used.
#>

[CmdLetBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string]$TaskName,
    [string]$ComputerName,
    [PSCredential]$AccessAccount
)

$Script:Cim = $null
[string[]]$Properties = @('TaskName','TaskPath','State','Description','URI','Author')
try{
    if([System.String]::IsNullOrWhiteSpace($ComputerName)){
        $ComputerName = [System.Net.DNS]::GetHostByName('').HostName
    }          
    if($null -eq $AccessAccount){
        $Script:Cim = New-CimSession -ComputerName $ComputerName -ErrorAction Stop
    }
    else {
        $Script:Cim = New-CimSession -ComputerName $ComputerName -Credential $AccessAccount -ErrorAction Stop
    }
    $task = Get-ScheduledTask -CimSession $Script:Cim -TaskName $TaskName -ErrorAction Stop
    $null = Start-ScheduledTask -InputObject $task -ErrorAction Stop
    
    $output = Get-ScheduledTask -CimSession $Script:Cim -TaskName $TaskName -ErrorAction Stop | Select-Object $Properties
    if($SRXEnv) {
        $SRXEnv.ResultMessage = $output
    }
    else{
        Write-Output $output
    }
}
catch{
    throw
}
finally{
    if($null -ne $Script:Cim){
        Remove-CimSession $Script:Cim 
    }
}
}