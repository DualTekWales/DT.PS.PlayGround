function Get-ScheduledTaskPrincipal {
<#
.Synopsis
    Get task that runs with specified principal.

.DESCRIPTION
    Gets the task that runs with the specified principal on the specified server.

    In combination with the activedirectory module you can run this on every server in your domain.
    
.EXAMPLE
    Get all tasks running under the specified principal on the specified server.

    Get-ScheduledTaskPrincipal -Principal Domain\ExampleUser -ComputerName ExampleSrv

    TaskPath                                       TaskName                          State      PSComputerName                                                                                                                                            
    --------                                       --------                          -----      --------------                                                                                                                                            
    \                                              CreateExplorerShellUnelevatedTask Running    ExampleSrv                                                                                                                                   
    \                                              LogBadLogonAttempts               Ready      ExampleSrv

.EXAMPLE
    Get all tasks on all server running with the specified principal

    $ADServer = All server in the current active directory. You need to build this array yourself.

    $ADServer | ForEach-Object{Get-ScheduledTaskPrincipal -Principal Domain\ExampleUser -ComputerName $_}

    TaskPath                                       TaskName                          State      PSComputerName                                                                                                                                            
    --------                                       --------                          -----      --------------                                                                                                                                            
    \                                              CreateExplorerShellUnelevatedTask Running    ExampleSrv                                                                                                                                   
    \                                              LogBadLogonAttempts               Ready      ExampleSrv
    \                                              CreateExplorerShellUnelevatedTask Running    ExampleSrv2                                                                                                                                  
    \                                              CreateExplorerShellUnelevatedTask Running    ExampleSrv3
    ...                                                                                                                                  

.NOTES
    Written and testet in PowerShell 5.1.

	Created:    26/10/2023
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release

#>   
    [CmdletBinding(DefaultParameterSetName='GetScheduledTaskPrincipal', 
               SupportsShouldProcess=$true)]
    param(
        [Parameter(
        ParameterSetName='GetScheduledTaskPrincipal',
        Position=0,
        Mandatory,
        HelpMessage='Principal name (Domain\Principal).')]
        [String]$Principal,

        [Parameter(
        ParameterSetName='GetScheduledTaskPrincipal',
        Position=1,
        HelpMessage='Computername.')]
        [String]$ComputerName = $env:COMPUTERNAME
    )

    if($Principal){
        Get-ScheduledTask -CimSession $ComputerName | Where-Object { $_.Principal.userid -eq $Principal}
    }
}
