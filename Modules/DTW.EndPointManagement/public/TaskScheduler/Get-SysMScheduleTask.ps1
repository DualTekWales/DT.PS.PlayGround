function Get-SysMScheduledTask {
<#
.SYNOPSIS
    Gets the task definition object of a scheduled task that is registered on the computer

.DESCRIPTION

.NOTES
	Created:    26/10/2023
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release

.Parameter TaskName
    Specifies the name of a scheduled task. Use * for all tasks    

.Parameter TaskPath 
    Specifies the path for scheduled task in Task Scheduler namespace. Use * for all paths

.Parameter ComputerName
    Specifies the name of the computer from which to retrieve the schedule tasks.
    
.Parameter AccessAccount
    Specifies a user account that has permission to perform this action. If Credential is not specified, the current user account is used.

.Parameter Properties
    List of properties to expand, comma separated e.g. Name,Description. Use * for all properties
#>

[CmdLetBinding()]
Param(
    [string]$TaskName = "*",
    [string]$TaskPath = "*",
    [string]$ComputerName,
    [PSCredential]$AccessAccount,
    [ValidateSet('*','TaskName','TaskPath','Description','URI','State','Author')]
    [string[]]$Properties = @('TaskName','TaskPath','Description','URI','State','Author')
)

$Script:Cim=$null
try{
    if([System.String]::IsNullOrWhiteSpace($TaskName)){
        $TaskName= "*"
    }
    if([System.String]::IsNullOrWhiteSpace($TaskPath)){
        $TaskPath= "*"
    }
    if($Properties -contains '*'){
        $Properties = @('*')
    }
    else{
        if($null -eq ($Properties | Where-Object {$_ -like 'TaskName'})){
            $Properties += "TaskName"
        }
    }

    if([System.String]::IsNullOrWhiteSpace($ComputerName)){
        $ComputerName = [System.Net.DNS]::GetHostByName('').HostName
    }          
    if($null -eq $AccessAccount){
        $Script:Cim = New-CimSession -ComputerName $ComputerName -ErrorAction Stop
    }
    else {
        $Script:Cim = New-CimSession -ComputerName $ComputerName -Credential $AccessAccount -ErrorAction Stop
    }

    $tasks = Get-ScheduledTask -CimSession $Script:Cim -TaskName $TaskName -TaskPath $TaskPath -ErrorAction Stop  `
                    | Select-Object $Properties | Sort-Object TaskName | Format-List
    if($SRXEnv) {
        $SRXEnv.ResultMessage = $tasks 
    }
    else{
        Write-Output $tasks
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