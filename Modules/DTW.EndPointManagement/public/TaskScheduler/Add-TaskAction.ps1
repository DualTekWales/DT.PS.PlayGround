function Add-TaskAction {
    <#
    .Synopsis
        Adds an action to a task definition
    .Description
        Adds an action to a task definition.
        You can create a task definition with New-Task, or use an existing definition from Get-ScheduledTask
    .Example
        New-Task -Disabled |
            Add-TaskTrigger  $EVT[0] |
            Add-TaskAction -Path Calc |
            Register-ScheduledTask "$(Get-Random)" 
    .Link
        Register-ScheduledTask
    .Link
        Add-TaskTrigger
    .Link
        Get-ScheduledTask
    .Link
        New-Task
    .NOTES
        Created:    01/01/2024
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release
    #>
    [CmdletBinding(DefaultParameterSetName="Script")]
    param(
    # The Scheduled Task Definition
    [Parameter(Mandatory=$true, 
        ValueFromPipeline=$true)]
    [__ComObject]
    $Task,
 
    # The script to run       
    [Parameter(Mandatory=$true,ParameterSetName="Script")]
    [ScriptBlock]
    $Script,
    
    # If set, will run PowerShell.exe with -WindowStyle Minimized
    [Parameter(ParameterSetName="Script")]
    [Switch]
    $Hidden,
    
    # If set, will run PowerShell.exe
    [Parameter(ParameterSetName="Script")]    
    [Switch]
    $Sta,
    
    # The path to the program.
    [Parameter(Mandatory=$true,ParameterSetName="Path")]
    [string]
    $Path,
    
    # The arguments to pass to the program.
    [Parameter(ParameterSetName="Path")]
    [string]
    $Arguments,    
    
    # The working directory the action will run in.  
    # By default, this will be the current directory
    [String]
    $WorkingDirectory = $PWD,
    
    # If set, the powershell script will not exit when it is completed
    [Parameter(ParameterSetName="Script")]
    [Switch]
    $NoExit,
    
    # The identifier of the task
    [String]
    $Id
    )
    
    begin {
        Set-StrictMode -Off
    }

    process {
        if ($Task.Definition) {  $Task = $Task.Definition }

        $Action = $Task.Actions.Create(0)
        if ($Id) { $Action.ID = $Id }
        $Action.WorkingDirectory = $WorkingDirectory
        switch ($psCmdlet.ParameterSetName) {
            Script {
                $action.Path = Join-Path $psHome "PowerShell.exe"
                $action.WorkingDirectory = $pwd
                $action.Arguments = ""
                if ($Hidden) {
                    $action.Arguments += " -WindowStyle Hidden"
                }
                if ($sta) {
                    $action.Arguments += " -Sta"
                }
                if ($NoExit) {
                    $Action.Arguments += " -NoExit"
                }
                $encodedScriptBlock = 
                $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))
                $action.Arguments+= " -encodedCommand $encodedCommand"
            }
            Path {
                $action.Path = $Path
                $action.Arguments = $Arguments
            }
        }
        $Task
    }
}