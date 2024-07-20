function Export-ScheduledTask {
    <#
		.SYNOPSIS
			Exports scheduled tasks in the form of XML files.

		.DESCRIPTION
			By default, it exports tasks from root to the C:\temp\backup directory.

		.PARAMETER  Computername
			Machines from which scheduled tasks will be backed up.

		.PARAMETER  TaskPath
			The path from which the tasks will be exported. The default value is "\" i.e. root. Write in the form "\Administration" "\Microsoft\Windows" etc.

		.PARAMETER  BackupPath
			Where the XML will be stored.
			
		.EXAMPLE
			Export-ScheduledTasks
			Exports tasks from root to C:\temp\backup directory

		.EXAMPLE
			Export-ScheduledTasks -comp sirene01 -taskPath "\Správa"
			Exports tasks from "\Admin" to directory C:\temp\backup on siren01

		.NOTES
            Created:    26/10/2023
            Author:     Mark White
            Version:    0.0.1
            Updated:    
            History:    0.0.1 - Initial release

	#>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        $Computername = $env:COMPUTERNAME
        ,
        [Parameter(Position = 1)]
        [ValidateNotNull()]
        [ValidatePattern('(?# Path must start with \)^\\')] # checking that it starts with a slash
        $TaskPath = "\"
        ,
        [Parameter(Position = 2)]
        [ValidateNotNull()]
        [ValidateScript( {Test-Path $_})] # checking if the path exists
        #		[ValidateScript({$_ -match "^\\\\\\w+\\\\w+"})] # check if it is a UNC path
        $BackupPath = "C:\temp\backup"
		
    )

    PROCESS {
        ForEach ($Computer in $Computername) {
            if (!(Test-Path $BackupPath )) { New-Item -type directory "$BackupPath" }
            $sch = New-Object -ComObject("Schedule.Service")
            $sch.Connect("$Computer")
            $tasks = $sch.GetFolder("$TaskPath").GetTasks(0)
            $tasks | ForEach-Object {
                $xml = $_.Xml
                $task_name = $_.Name
                $outfile = "$BackupPath\{0}.xml" -f $task_name
                $xml | Out-File $outfile
            }
        }	
    }
}
