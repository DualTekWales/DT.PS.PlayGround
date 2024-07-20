function Unregister-SysMScheduleTask {
<#
.SYNOPSIS
    Unregisters a scheduled task

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
    Specifies the name of the computer on which to unregister the schedule task
    
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
    $null = Get-ScheduledTask -CimSession $Script:Cim -TaskName $TaskName -ErrorAction Stop
    $null = Unregister-ScheduledTask -CimSession $Script:Cim -TaskName $TaskName -Confirm:$false -ErrorAction Stop
    
    if($SRXEnv) {
        $SRXEnv.ResultMessage = "Task: $($TaskName) deregistered"
    }
    else{
        Write-Output "Task: $($TaskName) deregistered"
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