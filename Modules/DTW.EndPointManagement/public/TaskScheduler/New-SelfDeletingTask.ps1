function New-SelfDeletingTask {
<# 
    .SYNOPSIS
        Create a self-deleting Scheduled Task.

    .DESCRIPTION 
        See .SYNOPSIS

    .NOTES

    .PARAMETER AdminUserAccount
        This parameter is MANDATORY.

        This parameter takes a string that represents the admin user that the Scheduled Task run as. It must be in format
        $env:ComputerName\<UserName> or <DomainShort>\<UserName>.

    .PARAMETER InMemory
        This parameter is MANDATORY.

        This parameter takes a securestring that represents the password for -AdminuserAccount.

    .PARAMETER Scriptblock
        This parameter is MANDATORY.

        This parameter takes a scriptblock that the Scheduled Task will execute.

    .PARAMETER ScriptTimeLimitInMinutes
        This parameter is MANDATORY.

        This parameter takes an integer that represents the number of minutes that the Scheduled Task will be allowed to run
        before it is forcibly killed.

    .PARAMETER WhenToExecute
        This parameter is MANDATORY.

        This parameter takes either a string (valid values 'Immediately','AtLogon','AtStartup') or a System.DateTime object
        that represent when the Scheduled Task will run.

    .PARAMETER TranscriptPath
        This parameter is OPTIONAL, however, a default value of "$HOME\SelfDelTask_$(Get-Date -f ddMMyy_hhmmss).txt" is set.

        This parameter takes a string that represents the full path to a file that will contain a transcript of what the
        -Scriptblock does.

    .PARAMETER TaskName
        This parameter is OPTIONAL, however, a default value of "selfdeltask" is set.

        This parameter takes a string that represents the name of the new self-deleting Scheduled Task.

    .EXAMPLE
        # Launch powershell and...

        PS C:\Users\zeroadmin> $SB = {$null = New-Item -ItemType Directory -Path "C:\SelfDelTaskTestA"}
        PS C:\Users\zeroadmin> $UserAcct = 'zero\zeroadmin'
        PS C:\Users\zeroadmin> $PwdSS = Read-Host -Prompt "Enter passsword for $UserAcct" -AsSecureString
        PS C:\Users\zeroadmin> New-SelfDeletingTask -AdminUserAccount $UserAcct -PasswordSS $PwdSS -Scriptblock $SB -ScriptTimeLimitInMinutes 1 -WhenToExecute 'Immediately'
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True)]
        $AdminUserAccount, # Should be in format $env:ComputerName\<UserName> or <DomainShort>\<UserName>

        [Parameter(Mandatory=$True)]
        [securestring]$PasswordSS,

        [Parameter(Mandatory=$True)]
        [scriptblock]$Scriptblock,

        [Parameter(Mandatory=$True)]
        [int]$ScriptTimeLimitInMinutes, # Put a time limit on how long the script should take before killing it

        [Parameter(Mandatory=$True)]
        [ValidateScript({
            $ObjType = $_.GetType().FullName
            switch ($_) {
                'Immediately'                       {$True}
                'AtLogon'                           {$True}
                'AtStartup'                         {$True}
                {$ObjType -eq "System.DateTime"}    {$True}
                Default                             {$False}
            }
        })]
        $WhenToExecute,

        [Parameter(Mandatory=$False)]
        [string]$TranscriptPath = "$HOME\SelfDelTask_$(Get-Date -f ddMMyy_hhmmss).txt",

        [Parameter(Mandatory=$False)]
        [string]$TaskName = 'selfdeltask'
    )

    #region >> Helper Functions

    function NewUniqueString {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory=$False)]
            [string[]]$ArrayOfStrings,
    
            [Parameter(Mandatory=$True)]
            [string]$PossibleNewUniqueString
        )
    
        if (!$ArrayOfStrings -or $ArrayOfStrings.Count -eq 0 -or ![bool]$($ArrayOfStrings -match "[\w]")) {
            $PossibleNewUniqueString
        }
        else {
            $OriginalString = $PossibleNewUniqueString
            $Iteration = 1
            while ($ArrayOfStrings -contains $PossibleNewUniqueString) {
                $AppendedValue = "_$Iteration"
                $PossibleNewUniqueString = $OriginalString + $AppendedValue
                $Iteration++
            }
    
            $PossibleNewUniqueString
        }
    }

    #endregion >> Helper Functions

    #region >> Prep

    if ($AdminUserAccount -notmatch "\\") {
        Write-Error "The format of -AdminUserAccount should be '$env:ComputerName\<UserName>' or '<DomainShort>\<UserName>'! Halting!"
        $global:FunctionResult = "1"
        return
    }

    $tmpDir = [IO.Path]::GetTempPath()
    $SchTaskScriptPath = "$tmpdir\selfdeletingtask.ps1"
    $TaskDonePath = "$tmpdir\TaskDone_$(Get-Date -f ddMMyy+hhmmss)"
    $PlainTextPwd = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($PasswordSS))
    $TaskName = NewUniqueString -ArrayOfStrings $(Get-ScheduledTask).TaskName -PossibleNewUniqueString $TaskName

    #endregion >> Prep

    #region >> Main

    try {
        # Create selfdeletingtask.ps1 that your Scheduled Task will run and then delete
        [System.Collections.Generic.List[string]]$SBAsArrayOfStrings = $ScriptBlock.ToString() -split "`n"
        if ($SBAsArrayOfStrings -notmatch "Start-Transcript") {
            $null = $SBAsArrayOfStrings.Insert(0,"Start-Transcript -Path '$TranscriptPath' -Append")
        }
        if ($SBAsArrayOfStrings -notmatch "Stop-Transcript") {
            $null = $SBAsArrayOfStrings.Add('Stop-Transcript')
        }
        if ($SBAsArrayOfStrings -notmatch [regex]::Escape("Set-Content -Path '$TaskDonePath' -Value 'TaskDone'")) {
            $null = $SBAsArrayOfStrings.Add("Set-Content -Path '$TaskDonePath' -Value 'TaskDone'")
        }
        if ($SBAsArrayOfStrings -notmatch "Unregister-ScheduledTask") {
            $null = $SBAsArrayOfStrings.Add("`$null = Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$False")
        }
        if ($SBAsArrayOfStrings -notmatch [regex]::Escape('Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force')) {
            $null = $SBAsArrayOfStrings.Add('Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force')
        }
        #$FinalSB = [scriptblock]::Create($($SBAsArrayOfStrings -join "`n"))
        Set-Content -Path $SchTaskScriptPath -Value $SBAsArrayOfStrings
    }
    catch {
        Write-Error $_
        $global:FunctionResult = "1"
        return
    }

    try {
        switch ($WhenToExecute) {
            'Immediately'                                   {$Trigger = New-ScheduledTaskTrigger -Once -At $(Get-Date).AddSeconds(10)}
            'AtLogon'                                       {$Trigger = New-ScheduledTaskTrigger -AtLogon -User $AdminUserAccount}
            'AtStartup'                                     {$Trigger = New-ScheduledTaskTrigger -AtStartup}
            {$_.GetType().FullName -eq "System.DateTime"}   {$Trigger = New-ScheduledTaskTrigger -Once -At $WhenToExecute}
        }
        if (!$Trigger) {
            throw "Problem defining `$Trigger (i.e. New-ScheduledTaskTrigger)! Halting!"
        }
    }
    catch {
        Write-Error $_
        $global:FunctionResult = "1"
        return
    }
    
    try {
        # Put a time limit on how long the script should/can take before killing it
        $Trigger.EndBoundary = $(Get-Date).AddMinutes($ScriptTimeLimitInMinutes).ToString('s')
        
        # IMPORTANT NOTE: The double quotes around the -File value are MANDATORY. They CANNOT be single quotes or without quote or the Scheduled Task will error out!
        $null = Register-ScheduledTask -Force -TaskName $TaskName -User $AdminUserAccount -Password $PlainTextPwd -Action $(
            New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File `"$SchTaskScriptPath`""
        ) -Trigger $Trigger -Settings $(New-ScheduledTaskSettingsSet -DeleteExpiredTaskAfter 00:00:01)

        $PlainTextPwd = $null
    }
    catch {
        $PlainTextPwd = $null
        Write-Error $_
        $global:FunctionResult = "1"
        return
    }

    $Counter = 0
    while ($(Get-ScheduledTask -TaskName $TaskName).State -ne "Ready" -and $Counter -lt 6) {
        Write-Verbose "Waiting for new Scheduled Task '$TaskName' to be 'Ready'..."
        Start-Sleep -Seconds 1
        $Counter++
    }
    if ($(Get-ScheduledTask -TaskName $TaskName).State -ne "Ready") {
        Write-Error "The new Scheduled Task '$TaskName' did not report 'Ready' within 30 seconds! Halting!"
        $global:FunctionResult = "1"
        return
    }

    if ($WhenToExecute -eq 'Immediately') {
        try {
            Start-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        }
        catch {
            Write-Error $_
            $global:FunctionResult = "1"
            return
        }

        # Wait for $ScriptTimeLimitInMinutes + 1 minutes or halt if the task fails
        $LastRunResultHT = @{
            '0'             = 'The operation completed successfully.'
            '1'             = 'Incorrect function called or unknown function called. 2 File not found.'
            '10'            = 'The environment is incorrect.'
            '267008'        = 'Task is ready to run at its next scheduled time.'
            '267009'        = 'Task is currently running. '
            '267010'        = 'The task will not run at the scheduled times because it has been disabled.'
            '267011'        = 'Task has not yet run.'
            '267012'        = 'There are no more runs scheduled for this task.'
            '267013'        = 'One or more of the properties that are needed to run this task on a schedule have not been set.'
            '267014'        = 'The last run of the task was terminated by the user.'
            '267015'        = 'Either the task has no triggers or the existing triggers are disabled or not set.'
            '2147750671'    = 'Credentials became corrupted.'
            '2147750687'    = 'An instance of this task is already running.'
            '2147943645'    = 'The service is not available (is "Run only when an user is logged on" checked?).'
            '3221225786'    = 'The application terminated as a result of a CTRL+C.'
            '3228369022'    = 'Unknown software exception.'
        }
        $LastRunResultRegex = $($LastRunResultHT.Keys | Where-Object {$_ -ne '0' -and $_ -ne '267009'} | ForEach-Object {'^' + $_ + '$'}) -join '|'

        $Counter = 0
        $ScriptTimeLimitInSeconds = $ScriptTimeLimitInMinutes/60
        while (!$(Test-Path $TaskDonePath) -and $LastRunResult -notmatch $LastRunResultRegex -and $Counter -le $($ScriptTimeLimitInSeconds+1)) {
            $Task = Get-ScheduledTask -TaskName $TaskName
            $TaskState = $Task.State
            $LastRunResult = $($Task | Get-ScheduledTaskInfo).LastRunResult

            $PercentComplete = [Math]::Round(($Counter/$ScriptTimeLimitInSeconds)*100)
            Write-Progress -Activity "Running Scheduled Task '$TaskName'" -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete
            Start-Sleep -Seconds 1
            $Counter++
        }

        if ($LastRunResult -match $LastRunResultRegex) {
            Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$False -ErrorAction SilentlyContinue

            [System.Collections.Generic.List[string]]$ErrMsg = @("The Scheduled Task '$TaskName' failed with the result code $LastRunResult, meaning '$($LastRunResultHT.$LastRunResult)'.")
            if (Test-Path $TranscriptPath) {
                $TranscriptContent = Get-Content $TranscriptPath
                $null = $ErrMsg.Add("Transcript output is as follows`n`n###BEGIN Transcript###`n`n$TranscriptContent`n`n###END Transcript###`n")
            }
            Write-Error $($ErrMsg -join "`n")
            $global:FunctionResult = "1"
            return
        }
        if ($Counter -gt $($ScriptTimeLimitInMinutes+1)) {
            Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$False -ErrorAction SilentlyContinue

            Write-Error "The Scheduled Task '$TaskName' did not complete within the alotted time (i.e. $ScriptTimeLimitInMinutes minutes)! Halting!"
            $global:FunctionResult = "1"
            return
        }

        if (Test-Path $TaskDonePath) {
            Remove-Item $TaskDonePath -Force
        }

        Write-Host "The Scheduled Task '$TaskName' completed successfully!" -ForegroundColor Green
    }

    #endregion >> Main
}
