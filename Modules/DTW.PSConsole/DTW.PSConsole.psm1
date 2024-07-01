
#region Functions to check and test

function Get-CurrentDay {
<#
.SYNOPSIS
	Determines the current day 
.DESCRIPTION
	This PowerShell script determines and speaks the current day by text-to-speech (TTS).
.EXAMPLE
	PS> ./check-day
	✔️ It's Sunday.
.NOTES
    Created:    04/01/2024
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
#>
	
	try
	{
		[system.threading.thread]::currentthread.currentculture = [system.globalization.cultureinfo]"en-US"
		$Weekday = (Get-Date -format "dddd")
		#Start-SpeakingEnglish "It's $Weekday."
	}
	catch
	{
		"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	}
}

function Get-CurrentMonth {
<#
.SYNOPSIS
	Gets the current month name
.DESCRIPTION
	This PowerShell script determines and speaks the current month name by text-to-speech (TTS).
.EXAMPLE
	PS> ./check-month
	✔️ It's December.
.NOTES
    Created:    04/01/2024
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
#>
	
	try
	{
		[system.threading.thread]::currentthread.currentculture = [system.globalization.cultureinfo]"en-GB"
		$MonthName = (Get-Date -UFormat %B)
		Write-Host "It's $MonthName."
	}
	catch
	{
		"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	}
}

function Get-DuskTime {
<#
.SYNOPSIS
	Checks the time of dusk 
.DESCRIPTION
	This PowerShell script queries the time of dusk and answers by text-to-speech (TTS).
.EXAMPLE
	PS> Get-DuskTime
	Dusk is in 2 hours at 8 PM.
.NOTES
        Created:    04/01/2024
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release
#>
	
	function TimeSpanToString
	{
		param ([TimeSpan]$Delta)
		$Result = ""
		if ($Delta.Hours -eq 1)
		{
			$Result += "1 hour and "
		}
		elseif ($Delta.Hours -gt 1)
		{
			$Result += "$($Delta.Hours) hours and "
		}
		if ($Delta.Minutes -eq 1)
		{
			$Result += "1 minute"
		}
		else
		{
			$Result += "$($Delta.Minutes) minutes"
		}
		return $Result
	}
	
	try
	{
		[system.threading.thread]::currentThread.currentCulture = [system.globalization.cultureInfo]"en-US"
		$String = (Invoke-WebRequest http://wttr.in/?format="%d" -UserAgent "curl" -useBasicParsing).Content
		$Hour, $Minute, $Second = $String -split ':'
		$Dusk = Get-Date -Hour $Hour -Minute $Minute -Second $Second
		$Now = [DateTime]::Now
		if ($Now -lt $Dusk)
		{
			$TimeSpan = TimeSpanToString($Dusk - $Now)
			$Reply = "Dusk is in $TimeSpan at $($Dusk.ToShortTimeString())."
		}
		else
		{
			$TimeSpan = TimeSpanToString($Now - $Dusk)
			$Reply = "Dusk was $TimeSpan ago at $($Dusk.ToShortTimeString())."
		}
		Write-Output $Reply
	}
	catch
	{
		"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	}
}

function Get-PowerDetails {
<#
.SYNOPSIS
	Checks the power status
.DESCRIPTION
	This PowerShell script queries the power status and prints it.
.EXAMPLE
	PS> ./check-power.ps1
	⚠️ Battery at 9% · 54 min remaining · power scheme 'HP Optimized' 
.NOTES
    Created:    04/01/2024
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
#>
	
	try
	{
		if ($IsLinux)
		{
			$reply = "✅ AC powered" # TODO, just guessing :-)
		}
		else
		{
			Add-Type -Assembly System.Windows.Forms
			$details = [System.Windows.Forms.SystemInformation]::PowerStatus
			[int]$percent = 100 * $details.BatteryLifePercent
			[int]$remaining = $details.BatteryLifeRemaining / 60
			if ($details.PowerLineStatus -eq "Online")
			{
				if ($details.BatteryChargeStatus -eq "NoSystemBattery")
				{
					$reply = "✅ AC powered"
				}
				elseif ($percent -ge 95)
				{
					$reply = "✅ Battery $percent% fully charged"
				}
				else
				{
					$reply = "✅ Battery charging... ($percent%)"
				}
			}
			else
			{
				# must be offline
				if (($remaining -eq 0) -and ($percent -ge 60))
				{
					$reply = "✅ Battery $percent% full"
				}
				elseif ($remaining -eq 0)
				{
					$reply = "✅ Battery at $percent%"
				}
				elseif ($remaining -le 5)
				{
					$reply = "⚠️ Battery at $percent% · ONLY $($remaining)min remaining"
				}
				elseif ($remaining -le 30)
				{
					$reply = "⚠️ Battery at $percent% · only $($remaining)min remaining"
				}
				elseif ($percent -lt 10)
				{
					$reply = "⚠️ Battery at $percent% · $($remaining)min remaining"
				}
				elseif ($percent -ge 60)
				{
					$reply = "✅ Battery $percent% full · $($remaining)min remaining"
				}
				else
				{
					$reply = "✅ Battery at $percent% · $($remaining)min remaining"
				}
			}
			$powerScheme = (powercfg /getactivescheme)
			$powerScheme = $powerScheme -Replace "^(.*)  \(", ""
			$powerScheme = $powerScheme -Replace "\)$", ""
			$reply += " · power scheme '$powerScheme'"
		}
		Write-Output $reply
	}
	catch
	{
		"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	}
}

function Get-RAMDetails {
<#
.SYNOPSIS
	Checks the RAM
.DESCRIPTION
	This PowerShell script queries the status of the installed RAM memory modules and prints it.
.EXAMPLE
	PS> ./check-ram.ps1
	✅ 16GB DDR4 RAM @ 3200MHz by Micron (in CPU0/CPU0-DIMM3 @ 1.2V)
.NOTES
    Created:    04/01/2024
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
#>
	
	function GetRAMType
	{
		param ([int]$Type)
		switch ($Type)
		{
			2 { return "DRAM" }
			5 { return "EDO RAM" }
			6 { return "EDRAM" }
			7 { return "VRAM" }
			8 { return "SRAM" }
			10 { return "ROM" }
			11 { return "Flash" }
			12 { return "EEPROM" }
			13 { return "FEPROM" }
			14 { return "EPROM" }
			15 { return "CDRAM" }
			16 { return "3DRAM" }
			17 { return "SDRAM" }
			18 { return "SGRAM" }
			19 { return "RDRAM" }
			20 { return "DDR RAM" }
			21 { return "DDR2 RAM" }
			22 { return "DDR2 FB-DIMM" }
			24 { return "DDR3 RAM" }
			26 { return "DDR4 RAM" }
			27 { return "DDR5 RAM" }
			28 { return "DDR6 RAM" }
			29 { return "DDR7 RAM" }
			default { return "RAM" }
		}
	}
	
	function Bytes2String
	{
		param ([int64]$Bytes)
		if ($Bytes -lt 1024) { return "$Bytes bytes" }
		$Bytes /= 1024
		if ($Bytes -lt 1024) { return "$($Bytes)KB" }
		$Bytes /= 1024
		if ($Bytes -lt 1024) { return "$($Bytes)MB" }
		$Bytes /= 1024
		if ($Bytes -lt 1024) { return "$($Bytes)GB" }
		$Bytes /= 1024
		if ($Bytes -lt 1024) { return "$($Bytes)TB" }
		$Bytes /= 1024
		if ($Bytes -lt 1024) { return "$($Bytes)PB" }
		$Bytes /= 1024
		if ($Bytes -lt 1024) { return "$($Bytes)EB" }
	}
	
	try
	{
		if ($IsLinux)
		{
			# TODO
		}
		else
		{
			$Banks = Get-WmiObject -Class Win32_PhysicalMemory
			foreach ($Bank in $Banks)
			{
				$Capacity = Bytes2String($Bank.Capacity)
				$Type = GetRAMType $Bank.SMBIOSMemoryType
				$Speed = $Bank.Speed
				[float]$Voltage = $Bank.ConfiguredVoltage / 1000.0
				$Manufacturer = $Bank.Manufacturer
				$Location = "$($Bank.BankLabel)/$($Bank.DeviceLocator)"
				Write-Host "✅ $Capacity $Type @ $($Speed)MHz by $Manufacturer (in $Location @ $($Voltage)V)"
			}
		}
	}
	catch
	{
		"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	}
}

function Get-SystemUptime {
<#
.SYNOPSIS
	Checks the uptime 
.DESCRIPTION
	This PowerShell script queries the computer's uptime (time between now and last boot up time) and prints it.
.EXAMPLE
	PS> ./check-uptime.ps1
	✅ Up for 2 days, 20 hours, 10 minutes
.NOTES
    Created:    04/01/2024
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
#>
	
	function TimeSpan2String([TimeSpan]$uptime)
	{
		[int]$days = $uptime.Days
		[int]$hours = $days * 24 + $uptime.Hours
		if ($days -gt 2)
		{
			return "$days days"
		}
		elseif ($hours -gt 1)
		{
			return "$hours hours"
		}
		else
		{
			return "$($uptime.Minutes)min"
		}
	}
	
	try
	{
		if ($IsLinux)
		{
			$uptime = (Get-Uptime)
			Write-Host "✅ Up for $(TimeSpan2String $uptime)"
		}
		else
		{
			[system.threading.thread]::currentthread.currentculture = [system.globalization.cultureinfo]"en-US"
			$lastBootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
			$uptime = New-TimeSpan -Start $lastBootTime -End (Get-Date)
			Write-Host "✅ Up for $(TimeSpan2String $uptime) since $($lastBootTime.ToShortDateString())"
		}
	}
	catch
	{
		"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	}
}

function Get-TimetoNewYear {
<#
.SYNOPSIS
	Checks the time until New Year
.DESCRIPTION
	This PowerShell script checks the time until New Year and replies by text-to-speech (TTS).
.EXAMPLE
	PS> Get-TimetoNewYear
.NOTES
    Created:    04/01/2024
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
#>
	
	try
	{
		$Now = [DateTime]::Now
		$NewYear = [Datetime]("12/31/" + $Now.Year)
		$Days = ($NewYear - $Now).Days + 1
		if ($Days -gt 1)
		{
			#Start-SpeakingEnglish "New Year is in $Days days."
		}
		elseif ($Days -eq 1)
		{
			#Start-SpeakingEnglish "New Year is tomorrow."
		}
	}
	catch
	{
		"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	}
}

function Get-WeekNumber {
<#
.SYNOPSIS
	Determines the week number 
.DESCRIPTION
	This PowerShell script determines and speaks the current week number by text-to-speech (TTS).
.EXAMPLE
	PS> Get-WeekNumber
.NOTES
    Created:    04/01/2024
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
#>
	
	try
	{
		$WeekNo = (Get-Date -UFormat %V)
		#Start-SpeakingEnglish "It's week #$WeekNo."
	}
	catch
	{
		"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	}
}

function Get-WindConditions {
<#
.SYNOPSIS
	Checks the wind conditions
.DESCRIPTION
	This PowerShell script determines the current wind conditions and replies by text-to-speech (TTS).
.PARAMETER location
	Specifies the location to use (determined automatically per default)
.EXAMPLE
	PS> Get-WindConditions
.NOTES
    Created:    04/01/2024
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
#>
	
	param ([string]$location = "") # empty means determine automatically
	
	try
	{
		$Weather = (Invoke-WebRequest http://wttr.in/${location}?format=j1 -userAgent "curl" -useBasicParsing).Content | ConvertFrom-Json
		$WindSpeed = $Weather.current_condition.windspeedKmph
		$WindDir = $Weather.current_condition.winddir16Point
		$Area = $Weather.nearest_area.areaName.value
		$Region = $Weather.nearest_area.region.value
		
		#Start-SpeakingEnglish "$($WindSpeed)km/h wind from $WindDir at $Area ($Region)."
	}
	catch
	{
		"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	}
}

function Get-PingLatency {
<#
.SYNOPSIS
	Checks the ping latency 
.DESCRIPTION
	This PowerShell script measures the ping roundtrip times from the local computer to other computers (10 Internet servers by default).
.PARAMETER hosts
	Specifies the hosts to check, seperated by commata (default is: amazon.com,bing.com,cnn.com,dropbox.com,github.com,google.com,live.com,meta.com,x.com,youtube.com)
.EXAMPLE
	PS> Get-PingLatency
	✅ Online with 18ms latency average (13ms...109ms, 0/10 ping loss)
.NOTES
    Created:    04/01/2024
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
#>
	
	param ([string]$hosts = "bing.com,cnn.com,dropbox.com,github.com,google.com,ibm.com,live.com,meta.com,x.com,youtube.com")
	
	try
	{
		$hostsArray = $hosts.Split(",")
		$parallelTasks = $hostsArray | ForEach-Object {
			(New-Object Net.NetworkInformation.Ping).SendPingAsync($_, 750)
		}
		[int]$min = 9999999
		[int]$max = [int]$avg = [int]$success = 0
		[int]$total = $hostsArray.Count
		[Threading.Tasks.Task]::WaitAll($parallelTasks)
		foreach ($ping in $parallelTasks.Result)
		{
			if ($ping.Status -ne "Success") { continue }
			$success++
			[int]$latency = $ping.RoundtripTime
			$avg += $latency
			if ($latency -lt $min) { $min = $latency }
			if ($latency -gt $max) { $max = $latency }
		}
		[int]$loss = $total - $success
		if ($success -ne 0)
		{
			$avg /= $success
			Write-Host "✅ Online with $($avg)ms latency average ($($min)ms...$($max)ms, $loss/$total ping loss)"
		}
		else
		{
			Write-Host "⚠️ Offline ($loss/$total ping loss)"
		}
	}
	catch
	{
		"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	}
}

function Get-CurrentMoonPhase {
<#
.SYNOPSIS
	Writes the moon phase
.DESCRIPTION
	This PowerShell script writes the current moon phase to the console.
.EXAMPLE
	PS> Get-CurrentMoonPhase
.NOTES
    Created:    04/01/2024
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
#>
	
	try
	{
		(Invoke-WebRequest http://wttr.in/Moon -userAgent "curl" -useBasicParsing).Content
	}
	catch
	{
		"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	}
}

#endregion Functions to check and test

# Check if console was started as admin
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    $AdminTitle = " [God Mode]"
    $IsAdmin = $true
}

function Out-VerboseTee {
    [CmdletBinding()]
    [alias("tv", "Tee-Verbose")]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$Value,
        [Parameter(Position = 0, Mandatory)]
        [string]$Path,
        [System.Text.Encoding]$Encoding,
        [switch]$Append
    )
    Begin {
        #turn on verbose pipeline since if you are running this command you intend for it to be on
        $VerbosePreference = "continue"
    }
    Process {
        #only run if Verbose is turned on
        if ($VerbosePreference -eq "continue") {
            $Value | Out-String | Write-Verbose
            [void]$PSBoundParameters.Remove("Append")
            if ($Append) {
                Add-Content @PSBoundParameters
            }
            else {
                Set-Content @PSBoundParameters
            }
        }
    }
    End {
        $VerbosePreference = "SilentlyContinue"
    }
} #close Out-VerboseTee

# Get IPv4-Address
function Get-ConsoleIPv4Address {
    If ($env:COMPUTERNAME.Equals(("M42449T")))
	{
		Get-NetIPAddress -InterfaceAlias 'Ethernet 2' -AddressFamily IPv4
	}
    ElseIf ($env:COMPUTERNAME.Equals(($HomePC)))
	{
		Get-NetIPAddress -InterfaceAlias 'Ethernet' -AddressFamily IPv4
	}
    elseif ($env:COMPUTERNAME.Equals(($HomeLaptop)))
	{
		Get-NetIPAddress -InterfaceAlias 'Ethernet 2' -AddressFamily IPv4
	}
	
	#Get-NetIPAddress -InterfaceIndex 10 -InterfaceAlias 'Ethernet' -AddressFamily IPv4
}

# PSVersion (e.g. 5.0.10586.494 or 4.0)
if ($PSVersionTable.PSVersion.Major -gt 6) {
    $PSConsole_PSVersion = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor).$($PSVersionTable.PSVersion.Patch)"
}
else {
    $PSConsole_PSVersion = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor).$($PSVersionTable.PSVersion.Build).$($PSVersionTable.PSVersion.Revision)"
}

# Get host uptime
function Get-ConsoleUptime() {
    $Uptime = (((Get-CimInstance -ClassName Win32_OperatingSystem).LocalDateTime) - ((Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime));
	
    $FormattedUptime = $Uptime.Days.ToString() + "d " + $Uptime.Hours.ToString() + "h " + $Uptime.Minutes.ToString() + "m " + $Uptime.Seconds.ToString() + "s ";
    return $FormattedUptime;
}

# Get computer make & model
function Get-ConsoleComputerSystem {
    (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer + " - " + (Get-CimInstance -ClassName Win32_ComputerSystem).Model
}

# Get computer processor
function Get-ConsoleCPU {
	(Get-CimInstance -ClassName Win32_Processor).Name
}

# Get computer processor count
function Get-ConsoleCPUCount {
	(Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfLogicalProcessors
}

# Get computer RAM Usage
function Get-ConsoleRAM() {
    $FreeRam = ([math]::Truncate((Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory / 1KB));
    $TotalRam = ([math]::Truncate((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1MB));
    $UsedRam = $TotalRam - $FreeRam;
    $FreeRamPercent = ($FreeRam / $TotalRam) * 100;
    $FreeRamPercent = "{0:N0}" -f $FreeRamPercent;
    $UsedRamPercent = ($UsedRam / $TotalRam) * 100;
    $UsedRamPercent = "{0:N0}" -f $UsedRamPercent;
    return $UsedRam.ToString() + " MB " + "(" + $UsedRamPercent.ToString() + "%" + ")" + " / " + $TotalRam.ToString() + " MB ";
}

# Get Computer Operating System Version
function Get-ConsoleOSVersion {
	(Get-CimInstance -ClassName Win32_OperatingSystem).Caption + " " + (Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture	
}

# Get OS Kernel Version
function Get-ConsoleKernel() {
	return (Get-CimInstance -ClassName  Win32_OperatingSystem).Version;
}

# Get Computer Displays
function Get-ConsoleDisplays() {
	if ($env:COMPUTERNAME -eq "labCLI01") {
        "Displays Not Supported"
    }
    else {
	$Displays = New-Object System.Collections.Generic.List[System.Object];
	
	# This gives the available resolutions
	$monitors = Get-CimInstance -N "root\wmi" -ClassName WmiMonitorListedSupportedSourceModes
	
	foreach ($monitor in $monitors)
	{
		# Sort the available modes by display area (width*height)
		$sortedResolutions = $monitor.MonitorSourceModes | Sort-Object -property { $_.HorizontalActivePixels * $_.VerticalActivePixels }
		$maxResolutions = $sortedResolutions | Select-Object @{ N = "MaxRes"; E = { "$($_.HorizontalActivePixels) x $($_.VerticalActivePixels) " } }
		
		$Displays.Add(($maxResolutions | Select-Object -last 1).MaxRes);
	}
	
	return $Displays;
    }
}

# Get time until Xmas
function Get-TimeToHoliday {
    <#
	.SYNOPSIS
		Checks the time until holiday
	.DESCRIPTION
		This script checks the time until holiday and replies by text-to-speech (TTS).
	.EXAMPLE
		PS> Get-TimeToholiday
	.NOTES
		Created:    26/10/2023
		Author:     Mark White
		Version:    0.0.1
		Updated:    
		History:    0.0.1 - Initial release
#>
    try {
        $Now = Get-Date
        $holiday = Get-Date -Month 01 -Day 09 -Year 2025
		$daysUntilholiday = ($holiday - $Now).Days

        $Reply = "$daysUntilholiday days until Bali & Lombock."
        "$Reply"

    }
    catch {
        "⚠️ Error: $($Error[0]) ($($MyInvocation.MyCommand.Name):$($_.InvocationInfo.ScriptLineNumber))"

    }
}

$PSConsole_IPv4Address = (Get-ConsoleIPv4Address).IPAddress
$PSConsole_IPv4Prefix = (Get-ConsoleIPv4Address).PrefixLength
$PSConsole_Uptime = Get-ConsoleUptime
$PSConsole_ComputerSystem = Get-ConsoleComputerSystem
$PSConsole_Processor = Get-ConsoleCPU
$PSConsole_ProcessorCount = Get-ConsoleCPUCount
$PSConsole_RAM = Get-ConsoleRAM
$PSConsole_OSVersion = Get-ConsoleOSVersion
$PSConsole_Kernel = Get-ConsoleKernel
$PSConsole_Displays = Get-ConsoleDisplays
$PSConsole_TimeToHoliday = Get-TimeToHoliday

# Setup Console Window
$Shell = $Host.UI.RawUI
$Shell.WindowTitle = "Windows PowerShell $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)" + $AdminTitle

$Size = $Shell.WindowSize
$Size.width = 200
$Size.height = 65
$Shell.WindowSize = $Size

$Size = $Shell.BufferSize
$Size.width = 200
$Size.height = 5000
$Shell.BufferSize = $Size

$Shell.BackgroundColor = "Black"
$Shell.ForegroundColor = "White"
if ($isAdmin) {
    $Shell.BackgroundColor = "Black"
    $Shell.ForegroundColor = "Gray"
}

# Startscreen / Clear-Host Text
function Write-StartScreen {

    $EmptyConsoleText = @"
                                                         ____                        ____  _          _ _     
     SS                                                 |  _ \ _____      _____ _ __/ ___|| |__   ___| | |    
     SSSSS                                              | |_) / _ \ \ /\ / / _ \ '__\___ \| '_ \ / _ \ | |    
     SSSSSSSS                                           |  __/ (_) \ V  V /  __/ |   ___) | | | |  __/ | |    
     SSSSSSSSSSS                                        |_|   \___/ \_/\_/ \___|_|  |____/|_| |_|\___|_|_|    
        SSSSSSSSSSS                                                                             
           SSSSSSSSSSS              +=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=+
           SSSSSSSSSSS              |
              SSSSSSSSSSS           |       Date & Time                     :       $(Get-Date -Format F)
                SSSSSSSSSSS         |       Domain\Username                 :       $env:USERDOMAIN \ $env:USERNAME
                SSSSSSSSSSS         |       Hostname                        :       $env:COMPUTERNAME
                SSSSSSSSSSS         |       Make & Model                    :       $PSConsole_ComputerSystem
                SSSSSSSSSSS         |       Displays                        :       $PSConsole_Displays
                SSSSSSSSSSS         |       Uptime                          :       $PSConsole_Uptime
                SSSSSSSSSSS         |       CPU & Cores                     :       $PSConsole_Processor / $PSConsole_ProcessorCount
                SSSSSSSSSSS         |       Memory                          :       $PSConsole_RAM
              SSSSSSSSSSS           |       IPv4-Address                    :       $PSConsole_IPv4Address / $PSConsole_IPv4Prefix
           SSSSSSSSSSS              |       Shell Version                   :       $PSConsole_PSVersion
        SSSSSSSSSSS                 |       OS Version & Kernel Version     :       $PSConsole_OSVersion / $PSConsole_Kernel
     SSSSSSSSSSS                    |       
     SSSSSSSSS                      |       My next holiday is in           >       $PSConsole_TimeToHoliday
     SSSSSSSS                       |
     SSSSS      SSSSSSSSSSSSSSS     +=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=+
     SSS      SSSSSSSSSSSSSSS                                                                    [ Mark.White@DualTek.Wales ] 
                                                                                

"@

    Write-Host -Object $EmptyConsoleText
}

# Overwrite default function "Clear-Host"
function Clear-Host {
    $space = New-Object System.Management.Automation.Host.BufferCell
    $space.Character = ' '
    $space.ForegroundColor = $host.ui.rawui.ForegroundColor
    $space.BackgroundColor = $host.ui.rawui.BackgroundColor
    $rect = New-Object System.Management.Automation.Host.Rectangle
    $rect.Top = $rect.Bottom = $rect.Right = $rect.Left = -1
    $origin = New-Object System.Management.Automation.Host.Coordinates
    $Host.UI.RawUI.CursorPosition = $origin
    $Host.UI.RawUI.SetBufferContents($rect, $space)
    Write-StartScreen
}

# Overwrite default function "prompt"
function global:prompt {
    $Success = $?

    ## Time calculation
    $LastExecutionTimeSpan = if (@(Get-History).Count -gt 0) {
        Get-History | Select-Object -Last 1 | ForEach-Object {
            New-TimeSpan -Start $_.StartExecutionTime -End $_.EndExecutionTime
        }
    }
    else {
        New-TimeSpan
    }

    $LastExecutionShortTime = if ($LastExecutionTimeSpan.Days -gt 0) {
        "$($LastExecutionTimeSpan.Days + [Math]::Round($LastExecutionTimeSpan.Hours / 24, 2)) d"
    }
    elseif ($LastExecutionTimeSpan.Hours -gt 0) {
        "$($LastExecutionTimeSpan.Hours + [Math]::Round($LastExecutionTimeSpan.Minutes / 60, 2)) h"
    }
    elseif ($LastExecutionTimeSpan.Minutes -gt 0) {
        "$($LastExecutionTimeSpan.Minutes + [Math]::Round($LastExecutionTimeSpan.Seconds / 60, 2)) m"
    }
    elseif ($LastExecutionTimeSpan.Seconds -gt 0) {
        "$($LastExecutionTimeSpan.Seconds + [Math]::Round($LastExecutionTimeSpan.Milliseconds / 1000, 2)) s"
    }
    elseif ($LastExecutionTimeSpan.Milliseconds -gt 0) {
        "$([Math]::Round($LastExecutionTimeSpan.TotalMilliseconds, 2)) ms"
    }
    else {
        "0 s"
    }

    if ($Success) {
        Write-Host -Object "[$LastExecutionShortTime] " -NoNewline -ForegroundColor Green
    }
    else {
        Write-Host -Object "! [$LastExecutionShortTime] " -NoNewline -ForegroundColor Red
    }

    ## History ID
    $HistoryId = $MyInvocation.HistoryId
    # Uncomment below for leading zeros
    # $HistoryId = '{0:d4}' -f $MyInvocation.HistoryId
    Write-Host -Object "$HistoryId`: " -NoNewline -ForegroundColor Cyan

    ## User
    #$IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    Write-Host -Object "($(if ($IsAdmin){ ' A ' } else { ' U ' })) " -NoNewline -ForegroundColor Yellow

    ## Path
    $Drive = $pwd.Drive.Name
    $Pwds = $pwd -split "\\" | Where-Object { -Not [String]::IsNullOrEmpty($_) }
    $PwdPath = if ($Pwds.Count -gt 3) {
        $ParentFolder = Split-Path -Path (Split-Path -Path $pwd -Parent) -Leaf
        $CurrentFolder = Split-Path -Path $pwd -Leaf
        "..\$ParentFolder\$CurrentFolder"
    }
    elseif ($Pwds.Count -eq 3) {
        $ParentFolder = Split-Path -Path (Split-Path -Path $pwd -Parent) -Leaf
        $CurrentFolder = Split-Path -Path $pwd -Leaf
        "$ParentFolder\$CurrentFolder"
    }
    elseif ($Pwds.Count -eq 2) {
        Split-Path -Path $pwd -Leaf
    }
    else { "" }

    Write-Host -Object "$Drive`:\$PwdPath" -NoNewline -ForegroundColor Magenta

    return " > "
}

# Clear Console and show start screen
Clear-Host