function Register-ScheduledTask {
    <#
    .Synopsis
        Registers a scheduled task.
    .Description
        Registers a scheduled task.
    .NOTES
        Created:    01/01/2024
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release

    #>
    [CmdletBinding()]
    param(
    # The name of the scheduled task to register
    [Parameter(Mandatory=$true,Position=0)]
    [string]
    $name,
    
    # The Scheduled Task to Register
    [Parameter(ValueFromPipeline=$true,
        Mandatory=$true)]
    [__ComObject]
    $Task,
        
    # The name of the computer to connect to.
    [string[]]
    $ComputerName,
    
    # The credential used to connect
    [Management.Automation.PSCredential]
    $Credential    
    )  
    
    begin {
        Set-StrictMode -Off
    }
    process {
        if ($task.Definition) { $Task = $task.Definition } 
        foreach ($c in $computerName) {
            $scheduler = Connect-ToTaskScheduler -ComputerName $c -Credential $Credential            
            if ($scheduler -and $scheduler.Connected) {
                $folder = $scheduler.GetFolder("")
                if ($Credential) {
                    $folder.RegisterTaskDefinition($Name, 
                        $Task, 
                        6,
                        $credential.UserName,
                        $credentail.GetNetworkCredential().Password,
                        6,
                        $null)
                } else {
                    $folder.RegisterTaskDefinition($Name, 
                        $Task, 
                        6,
                        "",
                        "",
                        3,
                        $null)                
                }                
            } 
        }
    }
}