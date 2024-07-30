
#region Functions to check and test



#endregion Functions to check and test

# Below is used for username entries in functions below
$dom = $env:userdomain
$usr = $env:username
$dn = ([adsi]"WinNT://$dom/$usr,user").fullname

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

# Check if console was started as admin
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
$AdminTitle = " [God Mode]"
$IsAdmin = $true
}

# get time till next holiday
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

function Get-ConsolePSStatus {
<#
.SYNOPSIS
    Check the PowerShell status
.DESCRIPTION
    This PowerShell script queries the PowerShell status and prints it.
.EXAMPLE
    PS> Get-ConsolePSStatus
    ✅ PowerShell 5.1.19041.2673 Desktop edition (10 modules, 1458 cmdlets, 172 aliases)
.NOTES
    Created:    04/01/2024
    Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
#>

try {
    $version = $PSVersionTable.PSVersion
    $edition = $PSVersionTable.PSEdition
    if ($IsLinux) {
        "PowerShell $version $edition Edition"
    } else {
        "PowerShell $version $edition Edition"
    }

} catch {
    "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"

}
}

function Get-ConsoleComputerInfo {
<#
.DESCRIPTION

.NOTES
Created:    26/10/2023
Author:     Mark White
Version:    0.0.1
Updated:    
History:    0.0.1 - Initial release

#>
[CmdletBinding()]
PARAM ($ComputerName)
# Computer System
$ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $ComputerName
# Operating System
$OperatingSystem = Get-CimInstance -ClassName win32_OperatingSystem -ComputerName $ComputerName

# Prepare Output
$Properties = @{
    ComputerName = $ComputerName
    Manufacturer = $ComputerSystem.Manufacturer
    Model = $ComputerSystem.Model
    OperatingSystem = $OperatingSystem.Caption
    OperatingSystemVersion = $OperatingSystem.Version
    SerialNumber = $Bios.SerialNumber
}

# Output Information
New-Object -TypeName PSobject -Property $Properties

}

function Get-ConsoleComputerSystem {
(Get-CimInstance -ClassName Win32_ComputerSystem).Model + " - " + (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
}

function Get-ConsoleCPUDetail {
<#
.SYNOPSIS
Checks the CPU status
.DESCRIPTION
This PowerShell script queries the CPU status (name, type, speed, temperature, etc) and prints it.
.EXAMPLE
PS> ./check-cpu.ps1
✅ Intel(R) Core(TM) i9-10900X CPU @ 3.70GHz (AMD64, 20 cores, CPU0, 3696MHz, CPU0 socket, 31.3°C)
.NOTES

#>

function GetCPUArchitecture {
if ("$env:PROCESSOR_ARCHITECTURE" -ne "") { return "$env:PROCESSOR_ARCHITECTURE" }
if ($IsLinux) {
    $Name = $PSVersionTable.OS
    if ($Name -like "*-generic *") {
        if ([System.Environment]::Is64BitOperatingSystem) { return "x64" } else { return "x86" }
    } elseif ($Name -like "*-raspi *") {
        if ([System.Environment]::Is64BitOperatingSystem) { return "ARM64" } else { return "ARM32" }
    } elseif ([System.Environment]::Is64BitOperatingSystem) { return "64-bit" } else { return "32-bit" }
}
}

function GetCPUTemperature {
<#
.SYNOPSIS
    Checks the CPU 
.DESCRIPTION
    This script checks the CPU temperature.
.EXAMPLE
    PS> Get-CPUTemperature
    ✔️ CPU has 30.3 °C
.NOTES
    Created:    26/10/2023
    Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
#>
try {
    if (test-path "/sys/class/thermal/thermal_zone0/temp" -pathType leaf) {
        [int]$IntTemp = get-content "/sys/class/thermal/thermal_zone0/temp"
        $Temp = [math]::round($IntTemp / 1000.0, 1)
    } else {
        $data = Get-CimInstance -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation -Namespace "root/CIMV2"
        $Temp = @($data)[0].HighPrecisionTemperature
        $Temp = [math]::round($Temp / 100.0, 1)
    }

    if ($Temp -gt 80) {
        $Reply = "$($Temp)"
    } elseif ($Temp -gt 50) {
        $Reply = "$($Temp)"
    } elseif ($Temp -gt 0) {
        $Reply = "$($Temp)"
    } elseif ($Temp -gt -20) {
        $Reply = "$($Temp)"
    } else {
        $Reply = "$($Temp)"
    }
    "$Reply"

} catch {
    "⚠️ Error: $($Error[0]) ($($MyInvocation.MyCommand.Name):$($_.InvocationInfo.ScriptLineNumber))"
}
}

try {
$arch = GetCPUArchitecture
if ($IsLinux) {
    $cpuName = "$arch CPU"
    $arch = ""
} else {
    $details = Get-CimInstance -ClassName Win32_Processor
    $cpuName = $details.Name.trim()
    $arch = "$arch, "
}
$cores = [System.Environment]::ProcessorCount
$celsius = GetCPUTemperature
if ($celsius -eq 99999.9) {
    $temp = "no temp"
} elseif ($celsius -gt 50) {
    $temp = "$($celsius)°C HOT"
} elseif ($celsius -lt 0) {
    $temp = "$($celsius)°C COLD"
} else {
    $temp = "$($celsius)°C OK"
} 

return "$cpuName ( $($cores) Cores ) - $temp"

} catch {
"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"

}

}

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

function Get-ConsoleOSDetails {
<#
.SYNOPSIS
Checks the OS status
.DESCRIPTION
This PowerShell script queries the operating system status and prints it.
.EXAMPLE
PS> Get-OSDetails
✅ Windows 10 Pro 64-bit (v10.0.19045, since 6/22/2021, S/N 00123-45678-15135-AAOEM, P/K AB123-CD456-EF789-GH000-WFR6P)
.NOTES
Created:    04/01/2024
Author:     Mark White
Version:    0.0.1
Updated:    
History:    0.0.1 - Initial release
#>

try {
if ($IsLinux) {
    $Name = $PSVersionTable.OS
    if ([System.Environment]::Is64BitOperatingSystem) { $Arch = "64-bit" } else { $Arch = "32-bit" }
    return "$Name (Linux $Arch)"
} else {
    $OS = Get-CimInstance -ClassName Win32_OperatingSystem
    $Name = $OS.Caption -Replace "Microsoft Windows","Windows"
    $Arch = $OS.OSArchitecture
    $Version = $OS.Version

    [system.threading.thread]::currentthread.currentculture = [system.globalization.cultureinfo]"en-GB"
    $OSDetails = Get-CimInstance Win32_OperatingSystem

    return "$Name $Arch ( v$Version )"
} 

} catch {
"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"

}
}

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

function Get-ConsoleGreeting {


$Hour = (Get-Date).Hour
If ( $Hour -lt 7 ) { "You're Working Early - $dn" }
elseif ( $Hour -lt 12 ) { "Good Morning - $dn" }
elseif ( $Hour -lt 16 ) { "Good Afternoon - $dn" }
elseif ( $Hour -lt 19 ) { "Good Evening - $dn" }
elseif ( $Hour -gt 20 ) { "What the hell are you still doing here? - $dn" }
else { "Good Afternoon - $dn" }
}

function Get-ConsoleLastBootUpTime {

[CmdletBinding()]
param(
    [parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$ComputerName,
    
    [System.Management.Automation.PSCredential]
    $Credential
)

begin {
    function Out-Object {
        param(
            [System.Collections.Hashtable[]] $hashData
        )

        $order = @()
        $result = @{ }
        $hashData | ForEach-Object {
            $order += ($_.Keys -as [Array])[0]
            $result += $_
        }
        New-Object PSObject -Property $result | Select-Object $order
    }

    function Format-TimeSpan {
        process {
            "{0:00}D {1:00}H {2:00}M {3:00}S" -f $_.Days, $_.Hours, $_.Minutes, $_.Seconds
        }
    }

    function Get-InnerUptime {
        param(
            $ComputerName,
            $Credential # -> # PSScriptAnalyzerTipp: must not use SecureString
        )

        # In case pipeline input contains ComputerName property
        if ($computerName.ComputerName) {
            $computerName = $computerName.ComputerName
        }

        if ((-not $computerName) -or ($computerName -eq ".")) {
            $computerName = [Net.Dns]::GetHostName()
        }

        $params = @{
            "Class"        = "Win32_OperatingSystem"
            "ComputerName" = $computerName
            "Namespace"    = "root\CIMV2"
        }

        if ( $credential ) {
            # Ignore -Credential for current computer
            if ($computerName -ne [Net.Dns]::GetHostName()) {
                $params.Add("Credential", $credential)
            }
        }

        try {
            $wmiOS = Get-WmiObject @params -ErrorAction Stop
        } catch {
            Write-Error -Exception (New-Object $_.Exception.GetType().FullName `
                ("Cannot connect to the computer '$computerName' due to the following error: '$($_.Exception.Message)'",
                    $_.Exception))
            return
        }

        $lastBootTime = [Management.ManagementDateTimeConverter]::ToDateTime($wmiOS.LastBootUpTime)
        Out-Object `
        @{"ComputerName" = $computerName},
        @{"LastBootTime" = $lastBootTime},
        @{"Uptime" = (Get-Date) - $lastBootTime | Format-TimeSpan}
    }
}

process {
    if ($ComputerName) {
        foreach ($computerNameItem in $ComputerName) {
            Get-InnerUptime $computerNameItem $Credential
        }
    } else {
        Get-InnerUptime "."
    }
}

#Get-Date -Format dd.MM.yyyy | Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object LastBootUpTime 

}

function Get-ConsolePowerDetails {
<#
.SYNOPSIS
Checks the power status
.DESCRIPTION
This PowerShell script queries the power status and prints it.
.EXAMPLE
PS> Get-ConsolePowerDetails
⚠️ Battery at 9% · 54 min remaining · power scheme 'HP Optimized' 
.NOTES
Created:    04/01/2024
Author:     Mark White
Version:    0.0.1
Updated:    
History:    0.0.1 - Initial release
#>

try {
if ($IsLinux) {
    $reply = "✅ AC Powered"
} else {
    Add-Type -Assembly System.Windows.Forms
    $details = [System.Windows.Forms.SystemInformation]::PowerStatus
    [int]$percent = 100 * $details.BatteryLifePercent
    [int]$remaining = $details.BatteryLifeRemaining / 60
    if ($details.PowerLineStatus -eq "Online") {
        if ($details.BatteryChargeStatus -eq "NoSystemBattery") {
            $reply = "AC Powered"
        } elseif ($percent -ge 95) {
            $reply = "Battery $percent% Fully Charged"
        } else {
            $reply = "Battery ($percent%)"
        }
    } else { # must be offline
        if (($remaining -eq 0) -and ($percent -ge 60)) {
            $reply = "Battery $percent% full"
        } elseif ($remaining -eq 0) {
            $reply = "Battery at $percent%"
        } elseif ($remaining -le 5) {
            $reply = "Battery at $percent% · ONLY $($remaining)min remaining"
        } elseif ($remaining -le 30) {
            $reply = "Battery at $percent% · only $($remaining)min remaining"
        } elseif ($percent -lt 10) {
            $reply = "Battery at $percent% · $($remaining)min remaining"
        } elseif ($percent -ge 60) {
            $reply = "Battery $percent% full · $($remaining)min remaining"
        } else {
            $reply = "Battery at $percent% · $($remaining)min remaining"
        }
    }
    $powerScheme = (powercfg /getactivescheme)
    $powerScheme = $powerScheme -Replace "^(.*)  \(",""
    $powerScheme = $powerScheme -Replace "\)$",""
    $reply += " / Power Scheme '$powerScheme'"
}
Write-Output $reply

} catch {
"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"

}
}

function Get-ConsoleDriveStat {
<#
.SYNOPSIS
    To get statistics on drives on a particular server or servers.
.DESCRIPTION
    To get statistics on drives on a server including Size, FreeSpace, and FreePct. Command line
    parameter allows for capacity statistics in Bytes, KB, MB, and GB
.NOTES
    Created:    26/10/2023
    Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release
.EXAMPLE
    Get-DriveStat

    ComputerName DeviceID VolumeName SizeGB FreeSpaceGB FreePct
    ------------ -------- ---------- ------ ----------- -------
    localhost    C:       Windows    237.14       19.56    8.25
.EXAMPLE
    Get-DriveStat -Capacity MB

    ComputerName DeviceID VolumeName    SizeMB FreeSpaceMB FreePct
    ------------ -------- ----------    ------ ----------- -------
    localhost    C:       Windows    242831.45    20026.65    8.25
.EXAMPLE
    Get-DriveStat -Verbose

    VERBOSE: Starting Get-DriveStat
    VERBOSE: Capacity will be expressed in [GB]
    VERBOSE: Processing MDA-102192

    ComputerName : localhost
    DeviceID     : C:
    VolumeName   : Windows
    SizeGB       : 237.14
    FreeSpaceGB  : 19.56
    FreePct      : 8.25

    VERBOSE: Ending Get-DriveStat

#>
[CmdletBinding()]
[OutputType('psobject')]
Param (
    [Parameter(Position = 0)]
    [ValidateNotNullorEmpty()]
    [Alias('CN', 'Server', 'ServerName', 'PSComputerName', 'SystemName')]
    [string[]] $ComputerName = $env:COMPUTERNAME,

    [Parameter(Position = 1, HelpMessage = "GB is selected by default")]
    [ValidateSet('Bytes', 'KB', 'MB', 'GB')]
    [string] $Capacity = 'GB'

)


    begin {
        Write-Verbose -Message "Starting [$($MyInvocation.Mycommand)]"
        Write-Verbose -Message "Capacity will be expressed in [$Capacity]"
        $Query = "Select * from Win32_LogicalDisk where DriveType='3' and FileSystem='NTFS'"
    }

    process {
        foreach ($C in $ComputerName) {
            Write-Verbose -Message "Processing $c"
            $DriveStat = Get-WMIObject -Query $Query -ComputerName $C
            switch ($Capacity) {
                'Bytes' {
                    $DriveStat |
                    Select-Object -Property @{name = 'ComputerName'; expression = { $_.SystemName } },
                    DeviceID,
                    VolumeName,
                    Size,
                    FreeSpace,
                    @{name = 'FreePct'; expression = { [double] ('{0:f2}' -f ($_.FreeSpace / $_.Size * 100)) } }
                }

                'KB' {
                    $DriveStat |
                    Select-Object -Property @{name = 'ComputerName'; expression = { $_.SystemName } },
                    DeviceID,
                    VolumeName,
                    @{name = 'SizeKB'     ; expression = { [double] ('{0:f2}' -f ($_.Size / 1KB)) } },
                    @{name = 'FreeSpaceKB'; expression = { [double] ('{0:f2}' -f ($_.FreeSpace / 1KB)) } },
                    @{name = 'FreePct'    ; expression = { [double] ('{0:f2}' -f ($_.FreeSpace / $_.Size * 100)) } }
                }

                'MB' {
                    $DriveStat |
                    Select-Object -Property @{name = 'ComputerName'; expression = { $_.SystemName } },
                    DeviceID,
                    VolumeName,
                    @{name = 'SizeMB'     ; expression = { [double] ('{0:f2}' -f ($_.Size / 1MB)) } },
                    @{name = 'FreeSpaceMB'; expression = { [double] ('{0:f2}' -f ($_.FreeSpace / 1MB)) } },
                    @{name = 'FreePct'    ; expression = { [double] ('{0:f2}' -f ($_.FreeSpace / $_.Size * 100)) } }
                }

                'GB' {
                    $DriveStat |
                    Select-Object -Property @{name = 'ComputerName'; expression = { $_.SystemName } },
                    DeviceID,
                    VolumeName,
                    @{name = 'SizeGB'     ; expression = { [double] ('{0:f2}' -f ($_.Size / 1GB)) } },
                    @{name = 'FreeSpaceGB'; expression = { [double] ('{0:f2}' -f ($_.FreeSpace / 1GB)) } },
                    @{name = 'FreePct'    ; expression = { [double] ('{0:f2}' -f ($_.FreeSpace / $_.Size * 100)) } }
                }
            }
        }

    }

    end {
        Write-Verbose -Message "Ending [$($MyInvocation.Mycommand)]"
    }
}

function Get-ConsoleAdminRightsStatus {
<#
.SYNOPSIS
    Check for admin rights
.DESCRIPTION
    This PowerShell script checks if the user has administrator rights.
.EXAMPLE
    PS> ./check-admin.ps1
    ✅ Yes, John has admin rights.
.NOTES

#>

try {
if ($IsLinux) {
    # todo
} else {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = (New-Object Security.Principal.WindowsPrincipal $user)
    if ($principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        "Yes, $dn has Admin Rights."
    } elseif ($principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Guest)) {
        "No, $dn, has Guest Rights Only."
    } else {
        "No, $dn has Normal User Rights Only."
    }
}  

} catch {
"⚠️ Error: $($Error[0]) (in script line $($_.InvocationInfo.ScriptLineNumber))"

}	
}

$PSConsole_IPv4Address = (Get-ConsoleIPv4Address).IPAddress
$PSConsole_IPv4Prefix = (Get-ConsoleIPv4Address).PrefixLength
$PSConsole_ComputerSystem = Get-ConsoleComputerSystem
$PSConsole_CPUDetails = Get-ConsoleCPUDetail
$PSConsole_PSVersion = Get-ConsolePSStatus
$PSConsole_RAM = Get-ConsoleRAM
$PSConsole_Displays = Get-ConsoleDisplays
$PSConsole_ExecPolicy = Get-ExecutionPolicy
$PSConsole_Greeting = Get-ConsoleGreeting
$PSConsole_Uptime = (Get-ConsoleLastBootUpTime).UpTime
$PSConsole_LastBootUpTime = (Get-ConsoleLastBootUpTime).LastBootTime
$PSConsole_PowerDetails = Get-ConsolePowerDetails
$PSConsole_DriveStatFree = (Get-ConsoleDriveStat).FreeSpaceGB
$PSConsole_DriveStatPct = (Get-ConsoleDriveStat).FreePct
$PSConsole_AdminRights = Get-ConsoleAdminRightsStatus
$PSConsole_OSDetails = Get-ConsoleOSDetails

$PSConsole_TimeToHoliday = Get-TimeToHoliday

# Setup Console Window
$Shell = $Host.UI.RawUI
$Shell.WindowTitle = "Windows PowerShell $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)" + $AdminTitle

<#

On surface
$Size = $Shell.WindowSize
$Size.width = 200
$Size.height = 65
$Shell.WindowSize = $Size

$Size = $Shell.BufferSize
$Size.width = 200
$Size.height = 500
$Shell.BufferSize = $Size

On laptop
$Size = $Shell.WindowSize
$Size.width = 175
$Size.height = 50
$Shell.WindowSize = $Size

$Size = $Shell.BufferSize
$Size.width = 175
$Size.height = 500
$Shell.BufferSize = $Size

On home laptop
$Size = $Shell.WindowSize
$Size.width = 200
$Size.height = 65
$Shell.WindowSize = $Size

$Size = $Shell.BufferSize
$Size.width = 200
$Size.height = 500
$Shell.BufferSize = $Size

#>

If ($env:COMPUTERNAME.Equals(($WorkDevice)))
{
$Size = $Shell.WindowSize
$Size.width = 200
$Size.height = 65
$Shell.WindowSize = $Size

$Size = $Shell.BufferSize
$Size.width = 200
$Size.height = 500
$Shell.BufferSize = $Size
}
ElseIf ($env:COMPUTERNAME.Equals(($HomeLP)))
{
$Size = $Shell.WindowSize
$Size.width = 175
$Size.height = 50
$Shell.WindowSize = $Size

$Size = $Shell.BufferSize
$Size.width = 175
$Size.height = 500
$Shell.BufferSize = $Size
}
ElseIf ($env:COMPUTERNAME.Equals(($HomePC)))
{
$Size = $Shell.WindowSize
$Size.width = 200
$Size.height = 65
$Shell.WindowSize = $Size

$Size = $Shell.BufferSize
$Size.width = 200
$Size.height = 500
$Shell.BufferSize = $Size
}
<#
Hidden from script as used in If statement above
$Size = $Shell.WindowSize
$Size.width = 200
$Size.height = 65
$Shell.WindowSize = $Size

$Size = $Shell.BufferSize
$Size.width = 200
$Size.height = 500
$Shell.BufferSize = $Size
#>
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
                            |  _ \ _____      _____ _ __/ ___|| |__   ___| | |    
                            | |_) / _ \ \ /\ / / _ \ '__\___ \| '_ \ / _ \ | |    
                            |  __/ (_) \ V  V /  __/ |   ___) | | | |  __/ | |    
                            |_|   \___/ \_/\_/ \___|_|  |____/|_| |_|\___|_|_|    

+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=+
|
|       Greeting                        :       $PSConsole_Greeting
|       Date & Time                     :       $(Get-Date -Format F)
|       Domain\Username                 :       $env:USERDOMAIN \ $env:USERNAME
|       Hostname                        :       $env:COMPUTERNAME
|       Make & Model                    :       $PSConsole_ComputerSystem
|       Operating System Details        :       $PSConsole_OSDetails
|       Drive Space Info                :       Free: $PSConsole_DriveStatFree GB / $PSConsole_DriveStatPct %
|       Memory                          :       $PSConsole_RAM
|       Power Details                   :       $PSConsole_PowerDetails
|       Displays                        :       $PSConsole_Displays
|       Uptime                          :       $PSConsole_Uptime / $PSConsole_LastBootUpTime
|       CPU Information                 :       $PSConsole_CPUDetails
|       IPv4-Address                    :       $PSConsole_IPv4Address / $PSConsole_IPv4Prefix
|       PowerShell Version              :       $PSConsole_PSVersion
|       Execution Policy                :       $PSConsole_ExecPolicy
|       Console Admin Status            :       $PSConsole_AdminRights
|       
|       My next holiday is in           >       $PSConsole_TimeToHoliday
|
+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=+

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