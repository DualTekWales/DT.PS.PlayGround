function Export-SysMScheduledTask {
<#
.SYNOPSIS
    Exports a scheduled task as an XML string

.DESCRIPTION

.NOTES
	Created:    26/10/2023
    Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release

.Parameter TaskName
    Specifies the name of a scheduled task

.Parameter ExportFile
    Specifies the name of the file to export

.Parameter ComputerName
    Specifies the name of the computer on which to export the schedule task
    
.Parameter AccessAccount
    Specifies a user account that has permission to perform this action. If Credential is not specified, the current user account is used.
#>

[CmdLetBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string]$TaskName,
    [string]$ExportFile,
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
    
    $output = Export-ScheduledTask -CimSession $Script:Cim -TaskName $TaskName -ErrorAction Stop
    if(-not [System.String]::IsNullOrWhiteSpace($ExportFile)){
        $output | Out-File $ExportFile
    }
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