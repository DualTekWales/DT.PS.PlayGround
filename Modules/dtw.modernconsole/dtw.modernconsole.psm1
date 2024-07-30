<#
Author: Mark White
Version: See manifest
Created: 30/07/2024
Updated: See manifest
#>

#region namespace

using namespace System.Net
using namespace System.Net.NetworkInformation

#endregion namespace

#region functions in test



#endregion function in test

#region Required Internal Functions - Do Not Delete

function Get-CimData {
<#
    .SYNOPSIS
	    Helper function for retreiving CIM data from local and remote computers

    .DESCRIPTION
	    Helper function for retreiving CIM data from local and remote computers

    .PARAMETER ComputerName
	    Specifies computer on which you want to run the CIM operation. You can specify a fully qualified domain name (FQDN), a NetBIOS name, or an IP address. If you do not specify this parameter, the cmdlet performs the operation on the local computer using Component Object Model (COM).

    .PARAMETER Protocol
	    Specifies the protocol to use. The acceptable values for this parameter are: DCOM, Default, or Wsman.

    .PARAMETER Class
	    Specifies the name of the CIM class for which to retrieve the CIM instances. You can use tab completion to browse the list of classes, because PowerShell gets a list of classes from the local WMI server to provide a list of class names.

    .PARAMETER Properties
	    Specifies a set of instance properties to retrieve. Use this parameter when you need to reduce the size of the object returned, either in memory or over the network. The object returned also contains the key properties even if you have not listed them using the Property parameter. Other properties of the class are present but they are not populated.

    .EXAMPLE
	    Get-CimData -Class 'win32_bios' -ComputerName AD1,AD2

	    Get-CimData -Class 'win32_bios'

	    # Get-CimClass to get all classes

    .NOTES
		Created:    26/10/2023
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release
        
    #>
	
	[CmdletBinding()]
	param (
		[parameter(Mandatory)]
		[string]$Class,
		[string]$NameSpace = 'root\cimv2',
		[string[]]$ComputerName = $Env:COMPUTERNAME,
		[ValidateSet('Default', 'Dcom', 'Wsman')]
		[string]$Protocol = 'Default',
		[string[]]$Properties = '*'
	)
	$ExcludeProperties = 'CimClass', 'CimInstanceProperties', 'CimSystemProperties', 'SystemCreationClassName', 'CreationClassName'
	
	# Querying CIM locally usually doesn't work. This means if you're querying same computer you neeed to skip CimSession/ComputerName if it's local query
	[Array]$ComputersSplit = Get-ComputerSplit -ComputerName $ComputerName
	
	$CimObject = @(
		# requires removal of this property for query
		[string[]]$PropertiesOnly = $Properties | Where-Object { $_ -ne 'PSComputerName' }
		# Process all remote computers
		$Computers = $ComputersSplit[1]
		if ($Computers.Count -gt 0)
		{
			if ($Protocol = 'Default')
			{
				Get-CimInstance -ClassName $Class -ComputerName $Computers -ErrorAction SilentlyContinue -Property $PropertiesOnly -Namespace $NameSpace -Verbose:$false -ErrorVariable ErrorsToProcess | Select-Object -Property $Properties -ExcludeProperty $ExcludeProperties
			}
			else
			{
				$Option = New-CimSessionOption -Protocol $Protocol
				$Session = New-CimSession -ComputerName $Computers -SessionOption $Option -ErrorAction SilentlyContinue
				$Info = Get-CimInstance -ClassName $Class -CimSession $Session -ErrorAction SilentlyContinue -Property $PropertiesOnly -Namespace $NameSpace -Verbose:$false -ErrorVariable ErrorsToProcess | Select-Object -Property $Properties -ExcludeProperty $ExcludeProperties
				$null = Remove-CimSession -CimSession $Session -ErrorAction SilentlyContinue
				$Info
			}
		}
		foreach ($E in $ErrorsToProcess)
		{
			Write-Warning -Message "Get-CimData - No data for computer $($E.OriginInfo.PSComputerName). Failed with errror: $($E.Exception.Message)"
		}
		# Process local computer
		$Computers = $ComputersSplit[0]
		if ($Computers.Count -gt 0)
		{
			$Info = Get-CimInstance -ClassName $Class -ErrorAction SilentlyContinue -Property $PropertiesOnly -Namespace $NameSpace -Verbose:$false -ErrorVariable ErrorsLocal | Select-Object -Property $Properties -ExcludeProperty $ExcludeProperties
			$Info | Add-Member -Name 'PSComputerName' -Value $Computers -MemberType NoteProperty -Force
			$Info
		}
		foreach ($E in $ErrorsLocal)
		{
			Write-Warning -Message "Get-CimData - No data for computer $($Env:COMPUTERNAME). Failed with errror: $($E.Exception.Message)"
		}
	)
	$CimObject
}

function ConvertTo-OperatingSystem {
<#
    .SYNOPSIS
	    Allows easy conversion of OperatingSystem, Operating System Version to proper Windows 10 naming based on WMI or AD

    .DESCRIPTION
	    Allows easy conversion of OperatingSystem, Operating System Version to proper Windows 10 naming based on WMI or AD

    .PARAMETER OperatingSystem
	    Operating System as returned by Active Directory

    .PARAMETER OperatingSystemVersion
	    Operating System Version as returned by Active Directory

    .NOTES
        Created:    26/10/2023
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release
	    
    .EXAMPLE
	    $Computers = Get-ADComputer -Filter * -Properties OperatingSystem, OperatingSystemVersion | ForEach-Object {
	        $OPS = ConvertTo-OperatingSystem -OperatingSystem $_.OperatingSystem -OperatingSystemVersion $_.OperatingSystemVersion
	        Add-Member -MemberType NoteProperty -Name 'OperatingSystemTranslated' -Value $OPS -InputObject $_ -Force
	        $_
	    }
	    $Computers | Select-Object DNS*, Name, SamAccountName, Enabled, OperatingSystem*, DistinguishedName | Format-Table

    .NOTES

#>
	[CmdletBinding()]
	param (
		[string]$OperatingSystem,
		[string]$OperatingSystemVersion
	)
	
	if ($OperatingSystem -like '*Windows 10*')
	{
		$Systems = @{
			# This is how it's written in AD
			'10.0 (19045)' = 'Windows 10 22H1'
			'10.0 (19044)' = 'Windows 10 21H2'
			'10.0 (19043)' = 'Windows 10 21H1'
			'10.0 (19042)' = 'Windows 10 20H2'
			'10.0 (19041)' = 'Windows 10 2004'
			'10.0 (18363)' = "Windows 10 1909"
			'10.0 (18362)' = "Windows 10 1903"
			'10.0 (17763)' = "Windows 10 1809"
			'10.0 (17134)' = "Windows 10 1803"
			'10.0 (16299)' = "Windows 10 1709"
			'10.0 (15063)' = "Windows 10 1703"
			'10.0 (14393)' = "Windows 10 1607"
			'10.0 (10586)' = "Windows 10 1511"
			'10.0 (10240)' = "Windows 10 1507"
			'10.0 (18898)' = 'Windows 10 Insider Preview'
			
			# This is how WMI/CIM stores it
			'10.0.19045'   = 'Windows 10 22H1'
			'10.0.19044'   = 'Windows 10 21H2'
			'10.0.19043'   = 'Windows 10 21H1'
			'10.0.19042'   = 'Windows 10 20H2'
			'10.0.19041'   = 'Windows 10 2004'
			'10.0.18363'   = "Windows 10 1909"
			'10.0.18362'   = "Windows 10 1903"
			'10.0.17763'   = "Windows 10 1809"
			'10.0.17134'   = "Windows 10 1803"
			'10.0.16299'   = "Windows 10 1709"
			'10.0.15063'   = "Windows 10 1703"
			'10.0.14393'   = "Windows 10 1607"
			'10.0.10586'   = "Windows 10 1511"
			'10.0.10240'   = "Windows 10 1507"
			'10.0.18898'   = 'Windows 10 Insider Preview'
		}
		$System = $Systems[$OperatingSystemVersion]
		if (-not $System)
		{
			$System = $OperatingSystem
		}
	}
	elseif ($OperatingSystem -like '*Windows Server*')
	{
		# May need updates https://docs.microsoft.com/en-us/windows-server/get-started/windows-server-release-info
		# to detect Core
		
		$Systems = @{
			'5.2 (3790)'   = 'Windows Server 2003'
			'6.1 (7601)'   = 'Windows Server 2008 R2'
			'6.2 (9200)'   = 'Windows Server 2012'
			'6.3 (9600)'   = 'Windows Server 2012 R2'
			# This is how it's written in AD
			'10.0 (18362)' = "Windows Server, version 1903 (Semi-Annual Channel) 1903" # (Datacenter Core, Standard Core)
			'10.0 (17763)' = "Windows Server 2019 (Long-Term Servicing Channel) 1809" # (Datacenter, Essentials, Standard)
			'10.0 (17134)' = "Windows Server, version 1803 (Semi-Annual Channel) 1803" # (Datacenter, Standard)
			'10.0 (14393)' = "Windows Server 2016 (Long-Term Servicing Channel) 1607"
			
			# This is how WMI/CIM stores it
			'10.0.18362'   = "Windows Server, version 1903 (Semi-Annual Channel) 1903" #  (Datacenter Core, Standard Core)
			'10.0.17763'   = "Windows Server 2019 (Long-Term Servicing Channel) 1809" # (Datacenter, Essentials, Standard)
			'10.0.17134'   = "Windows Server, version 1803 (Semi-Annual Channel) 1803" ## (Datacenter, Standard)
			'10.0.14393'   = "Windows Server 2016 (Long-Term Servicing Channel) 1607"
		}
		$System = $Systems[$OperatingSystemVersion]
		if (-not $System)
		{
			$System = $OperatingSystem
		}
	}
	else
	{
		$System = $OperatingSystem
	}
	if ($System)
	{
		$System
	}
	else
	{
		'Unknown'
	}
}

function ConvertFrom-LanguageCode {
<#
	.SYNOPSIS

	.DESCRIPTION

	.INPUTS

	.OUTPUTS

	.NOTES
    Created:    26/10/2023
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release

#>
	[cmdletBinding()]
	param (
		[string]$LanguageCode
	)
	$LanguageCodeDictionary = @{
		'1'	    = "Arabic"
		'4'	    = "Chinese (Simplified)?? China"
		'9'	    = "English"
		'1025'  = "Arabic (Saudi Arabia)"
		'1026'  = "Bulgarian"
		'1027'  = "Catalan"
		'1028'  = "Chinese (Traditional) Taiwan"
		'1029'  = "Czech"
		'1030'  = "Danish"
		'1031'  = "German (Germany)"
		'1032'  = "Greek"
		'1033'  = "English (United States)"
		'1034'  = "Spanish (Traditional Sort)"
		'1035'  = "Finnish"
		'1036'  = "French (France)"
		'1037'  = "Hebrew"
		'1038'  = "Hungarian"
		'1039'  = "Icelandic"
		'1040'  = "Italian (Italy)"
		'1041'  = "Japanese"
		'1042'  = "Korean"
		'1043'  = "Dutch (Netherlands)"
		'1044'  = "Norwegian (Bokmal)"
		'1045'  = "Polish"
		'1046'  = "Portuguese (Brazil)"
		'1047'  = "Rhaeto-Romanic"
		'1048'  = "Romanian"
		'1049'  = "Russian"
		'1050'  = "Croatian"
		'1051'  = "Slovak"
		'1052'  = "Albanian"
		'1053'  = "Swedish"
		'1054'  = "Thai"
		'1055'  = "Turkish"
		'1056'  = "Urdu"
		'1057'  = "Indonesian"
		'1058'  = "Ukrainian"
		'1059'  = "Belarusian"
		'1060'  = "Slovenian"
		'1061'  = "Estonian"
		'1062'  = "Latvian"
		'1063'  = "Lithuanian"
		'1065'  = "Persian"
		'1066'  = "Vietnamese"
		'1069'  = "Basque (Basque)"
		'1070'  = "Serbian"
		'1071'  = "Macedonian (FYROM)"
		'1072'  = "Sutu"
		'1073'  = "Tsonga"
		'1074'  = "Tswana"
		'1076'  = "Xhosa"
		'1077'  = "Zulu"
		'1078'  = "Afrikaans"
		'1080'  = "Faeroese"
		'1081'  = "Hindi"
		'1082'  = "Maltese"
		'1084'  = "Scottish Gaelic (United Kingdom)"
		'1085'  = "Yiddish"
		'1086'  = "Malay (Malaysia)"
		'2049'  = "Arabic (Iraq)"
		'2052'  = "Chinese (Simplified) PRC"
		'2055'  = "German (Switzerland)"
		'2057'  = "English (United Kingdom)"
		'2058'  = "Spanish (Mexico)"
		'2060'  = "French (Belgium)"
		'2064'  = "Italian (Switzerland)"
		'2067'  = "Dutch (Belgium)"
		'2068'  = "Norwegian (Nynorsk)"
		'2070'  = "Portuguese (Portugal)"
		'2072'  = "Romanian (Moldova)"
		'2073'  = "Russian (Moldova)"
		'2074'  = "Serbian (Latin)"
		'2077'  = "Swedish (Finland)"
		'3073'  = "Arabic (Egypt)"
		'3076'  = "Chinese Traditional (Hong Kong SAR)"
		'3079'  = "German (Austria)"
		'3081'  = "English (Australia)"
		'3082'  = "Spanish (International Sort)"
		'3084'  = "French (Canada)"
		'3098'  = "Serbian (Cyrillic)"
		'4097'  = "Arabic (Libya)"
		'4100'  = "Chinese Simplified (Singapore)"
		'4103'  = "German (Luxembourg)"
		'4105'  = "English (Canada)"
		'4106'  = "Spanish (Guatemala)"
		'4108'  = "French (Switzerland)"
		'5121'  = "Arabic (Algeria)"
		'5127'  = "German (Liechtenstein)"
		'5129'  = "English (New Zealand)"
		'5130'  = "Spanish (Costa Rica)"
		'5132'  = "French (Luxembourg)"
		'6145'  = "Arabic (Morocco)"
		'6153'  = "English (Ireland)"
		'6154'  = "Spanish (Panama)"
		'7169'  = "Arabic (Tunisia)"
		'7177'  = "English (South Africa)"
		'7178'  = "Spanish (Dominican Republic)"
		'8193'  = "Arabic (Oman)"
		'8201'  = "English (Jamaica)"
		'8202'  = "Spanish (Venezuela)"
		'9217'  = "Arabic (Yemen)"
		'9226'  = "Spanish (Colombia)"
		'10241' = "Arabic (Syria)"
		'10249' = "English (Belize)"
		'10250' = "Spanish (Peru)"
		'11265' = "Arabic (Jordan)"
		'11273' = "English (Trinidad)"
		'11274' = "Spanish (Argentina)"
		'12289' = "Arabic (Lebanon)"
		'12298' = "Spanish (Ecuador)"
		'13313' = "Arabic (Kuwait)"
		'13322' = "Spanish (Chile)"
		'14337' = "Arabic (U.A.E.)"
		'14346' = "Spanish (Uruguay)"
		'15361' = "Arabic (Bahrain)"
		'15370' = "Spanish (Paraguay)"
		'16385' = "Arabic (Qatar)"
		'16394' = "Spanish (Bolivia)"
		'17418' = "Spanish (El Salvador)"
		'18442' = "Spanish (Honduras)"
		'19466' = "Spanish (Nicaragua)"
		'20490' = "Spanish (Puerto Rico)"
	}
	$Output = $LanguageCodeDictionary[$LanguageCode]
	if ($Output)
	{
		$Output
	}
	else
	{
		"Unknown (Undocumented)"
	}
}

function Get-ComputerSplit {
<#
.SYNOPSIS

.DESCRIPTION

.INPUTS

.OUTPUTS

.NOTES
    Created:    26/10/2023
	Author:     Mark White
    Version:    0.0.1
    Updated:    
    History:    0.0.1 - Initial release

#>
	[CmdletBinding()]
	param (
		[string[]]$ComputerName
	)
	if ($null -eq $ComputerName)
	{
		$ComputerName = $Env:COMPUTERNAME
	}
	try
	{
		$LocalComputerDNSName = [System.Net.Dns]::GetHostByName($Env:COMPUTERNAME).HostName
	}
	catch
	{
		$LocalComputerDNSName = $Env:COMPUTERNAME
	}
	$ComputersLocal = $null
	[Array]$Computers = foreach ($Computer in $ComputerName)
	{
		if ($Computer -eq '' -or $null -eq $Computer)
		{
			$Computer = $Env:COMPUTERNAME
		}
		if ($Computer -ne $Env:COMPUTERNAME -and $Computer -ne $LocalComputerDNSName)
		{
			$Computer
		}
		else
		{
			$ComputersLocal = $Computer
		}
	}
	 , @($ComputersLocal, $Computers)
}

#endregion Required Internal Functions - Do Not Delete

# Below is used for username entries in functions below
$dom = $env:userdomain
$usr = $env:username
$dn = ([adsi]"WinNT://$dom/$usr,user").fullname

# Setup Console Window
$Shell = $Host.UI.RawUI
$Shell.WindowTitle = "PowerShell $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)" + $AdminTitle

function Out-VerboseTee {
	[CmdletBinding()]
	[alias("tv", "Tee-Verbose")]
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[object]$Value,
		[Parameter(Position = 0, Mandatory)]
		[string]$Path,
		[System.Text.Encoding]$Encoding,
		[switch]$Append
	)
	Begin
	{
		#turn on verbose pipeline since if you are running this command you intend for it to be on
		$VerbosePreference = "continue"
	}
	Process
	{
		#only run if Verbose is turned on
		if ($VerbosePreference -eq "continue")
		{
			$Value | Out-String | Write-Verbose
			[void]$PSBoundParameters.Remove("Append")
			if ($Append)
			{
				Add-Content @PSBoundParameters
			}
			else
			{
				Set-Content @PSBoundParameters
			}
		}
	}
	End
	{
		$VerbosePreference = "SilentlyContinue"
	}
} #close Out-VerboseTee

# Check if console was started as admin
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
{
	$AdminTitle = " [God Mode]"
	$IsAdmin = $true
}

#region Console functions

function Get-MCTimeToHoliday {
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
	try
	{
		$Now = Get-Date
		$holiday = Get-Date -Month 01 -Day 09 -Year 2025
		$daysUntilholiday = ($holiday - $Now).Days
		
		$Reply = "$daysUntilholiday days until Bali & Lombock."
		"$Reply"
		
	}
	catch
	{
		"⚠️ Error: $($Error[0]) ($($MyInvocation.MyCommand.Name):$($_.InvocationInfo.ScriptLineNumber))"
		
	}
}

function Get-MCIPv4Address {
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

function Get-MCPSVersion {
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
	
	try
	{
		$PSMajorVersion = $PSVersionTable.PSVersion.Major
		$PSMinorVersion = $PSVersionTable.PSVersion.Minor
		$PSBuildVersion = $PSVersionTable.PSVersion.Build
		$edition = $PSVersionTable.PSEdition
		if ($IsLinux)
		{
			"PowerShell $PSMajorVersion.$PSMinorVersion $edition Edition ( $PSBuildVersion Build )"
		}
		else
		{
			"PowerShell $PSMajorVersion.$PSMinorVersion $edition Edition ( $PSBuildVersion Build )"
		}
		
	}
	catch
	{
		"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
		
	}
}

function Get-MCComputerInfo {
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
		ComputerName		   = $ComputerName
		Manufacturer		   = $ComputerSystem.Manufacturer
		Model				   = $ComputerSystem.Model
		OperatingSystem	       = $OperatingSystem.Caption
		OperatingSystemVersion = $OperatingSystem.Version
		SerialNumber		   = $Bios.SerialNumber
	}
	
	# Output Information
	New-Object -TypeName PSobject -Property $Properties
	
}

function Get-MCComputerSystem {
	Get-CimInstance -ClassName Win32_ComputerSystem
}

function Get-MCCPUDetails {
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
	
	function GetCPUArchitecture
	{
		if ("$env:PROCESSOR_ARCHITECTURE" -ne "") { return "$env:PROCESSOR_ARCHITECTURE" }
		if ($IsLinux)
		{
			$Name = $PSVersionTable.OS
			if ($Name -like "*-generic *")
			{
				if ([System.Environment]::Is64BitOperatingSystem) { return "x64" }
				else { return "x86" }
			}
			elseif ($Name -like "*-raspi *")
			{
				if ([System.Environment]::Is64BitOperatingSystem) { return "ARM64" }
				else { return "ARM32" }
			}
			elseif ([System.Environment]::Is64BitOperatingSystem) { return "64-bit" }
			else { return "32-bit" }
		}
	}
	
	function GetCPUTemperature
	{
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
		try
		{
			if (test-path "/sys/class/thermal/thermal_zone0/temp" -pathType leaf)
			{
				[int]$IntTemp = get-content "/sys/class/thermal/thermal_zone0/temp"
				$Temp = [math]::round($IntTemp / 1000.0, 1)
			}
			else
			{
				$data = Get-CimInstance -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation -Namespace "root/CIMV2"
				$Temp = @($data)[0].HighPrecisionTemperature
				$Temp = [math]::round($Temp / 100.0, 1)
			}
			
			if ($Temp -gt 80)
			{
				$Reply = "$($Temp)"
			}
			elseif ($Temp -gt 50)
			{
				$Reply = "$($Temp)"
			}
			elseif ($Temp -gt 0)
			{
				$Reply = "$($Temp)"
			}
			elseif ($Temp -gt -20)
			{
				$Reply = "$($Temp)"
			}
			else
			{
				$Reply = "$($Temp)"
			}
			"$Reply"
			
		}
		catch
		{
			"⚠️ Error: $($Error[0]) ($($MyInvocation.MyCommand.Name):$($_.InvocationInfo.ScriptLineNumber))"
		}
	}
	
	try
	{
		$arch = GetCPUArchitecture
		if ($IsLinux)
		{
			$cpuName = "$arch CPU"
			$arch = ""
		}
		else
		{
			$details = Get-CimInstance -ClassName Win32_Processor
			$cpuName = $details.Name.trim()
			$arch = "$arch, "
		}
		$cores = [System.Environment]::ProcessorCount
		$celsius = GetCPUTemperature
		if ($celsius -eq 99999.9)
		{
			$temp = "no temp"
		}
		elseif ($celsius -gt 50)
		{
			$temp = "$($celsius)°C HOT"
		}
		elseif ($celsius -lt 0)
		{
			$temp = "$($celsius)°C COLD"
		}
		else
		{
			$temp = "$($celsius)°C OK"
		}
		
		return "$cpuName ( $($cores) Cores ) - $temp"
		
	}
	catch
	{
		"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
		
	}
	
}

function Get-MCRAMInfo() {
	$FreeRam = ([math]::Truncate((Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory / 1KB));
	$TotalRam = ([math]::Truncate((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1MB));
	$UsedRam = $TotalRam - $FreeRam;
	$FreeRamPercent = ($FreeRam / $TotalRam) * 100;
	$FreeRamPercent = "{0:N0}" -f $FreeRamPercent;
	$UsedRamPercent = ($UsedRam / $TotalRam) * 100;
	$UsedRamPercent = "{0:N0}" -f $UsedRamPercent;
	return $UsedRam.ToString() + " MB " + "(" + $UsedRamPercent.ToString() + "%" + ")" + " / " + $TotalRam.ToString() + " MB ";
}

function Get-MCOSDetails2 {
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
	
	try
	{
		if ($IsLinux)
		{
			$Name = $PSVersionTable.OS
			if ([System.Environment]::Is64BitOperatingSystem) { $Arch = "64-bit" }
			else { $Arch = "32-bit" }
			return "$Name (Linux $Arch)"
		}
		else
		{
			$OS = Get-CimInstance -ClassName Win32_OperatingSystem
			$Name = $OS.Caption -Replace "Microsoft Windows", "Windows"
			$Arch = $OS.OSArchitecture
			$Version = $OS.Version
			
			[system.threading.thread]::currentthread.currentculture = [system.globalization.cultureinfo]"en-GB"
			$OSDetails = Get-CimInstance Win32_OperatingSystem
			
			return "$Name $Arch ( v$Version )"
		}
		
	}
	catch
	{
		"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
		
	}
}

function Get-MCDisplays() {
	if ($env:COMPUTERNAME -eq "labCLI01")
	{
		"Displays Not Supported"
	}
	else
	{
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

function Get-MCGreeting {
	$Hour = (Get-Date).Hour
	If ($Hour -lt 7) { "You're Working Early - $dn" }
	elseif ($Hour -lt 12) { "Good Morning - $dn" }
	elseif ($Hour -lt 16) { "Good Afternoon - $dn" }
	elseif ($Hour -lt 19) { "Good Evening - $dn" }
	elseif ($Hour -gt 20) { "What the hell are you still doing here? - $dn" }
	else { "Good Afternoon - $dn" }
}

function Get-MCLastBootUpTime {
	
	[CmdletBinding()]
	param (
		[parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string]$ComputerName,
		[System.Management.Automation.PSCredential]$Credential
	)
	
	begin
	{
		function Out-Object
		{
			param (
				[System.Collections.Hashtable[]]$hashData
			)
			
			$order = @()
			$result = @{ }
			$hashData | ForEach-Object {
				$order += ($_.Keys -as [Array])[0]
				$result += $_
			}
			New-Object PSObject -Property $result | Select-Object $order
		}
		
		function Format-TimeSpan
		{
			process
			{
				"{0:00}D {1:00}H {2:00}M {3:00}S" -f $_.Days, $_.Hours, $_.Minutes, $_.Seconds
			}
		}
		
		function Get-InnerUptime
		{
			param (
				$ComputerName,
				$Credential # -> # PSScriptAnalyzerTipp: must not use SecureString
			)
			
			# In case pipeline input contains ComputerName property
			if ($computerName.ComputerName)
			{
				$computerName = $computerName.ComputerName
			}
			
			if ((-not $computerName) -or ($computerName -eq "."))
			{
				$computerName = [Net.Dns]::GetHostName()
			}
			
			$params = @{
				"Class"	       = "Win32_OperatingSystem"
				"ComputerName" = $computerName
				"Namespace"    = "root\CIMV2"
			}
			
			if ($credential)
			{
				# Ignore -Credential for current computer
				if ($computerName -ne [Net.Dns]::GetHostName())
				{
					$params.Add("Credential", $credential)
				}
			}
			
			try
			{
				$wmiOS = Get-WmiObject @params -ErrorAction Stop
			}
			catch
			{
				Write-Error -Exception (New-Object $_.Exception.GetType().FullName `
					("Cannot connect to the computer '$computerName' due to the following error: '$($_.Exception.Message)'",
						$_.Exception))
				return
			}
			
			$lastBootTime = [Management.ManagementDateTimeConverter]::ToDateTime($wmiOS.LastBootUpTime)
			Out-Object `
					   @{ "ComputerName" = $computerName },
					   @{ "LastBootTime" = $lastBootTime },
					   @{ "Uptime" = (Get-Date) - $lastBootTime | Format-TimeSpan }
		}
	}
	
	process
	{
		if ($ComputerName)
		{
			foreach ($computerNameItem in $ComputerName)
			{
				Get-InnerUptime $computerNameItem $Credential
			}
		}
		else
		{
			Get-InnerUptime "."
		}
	}
	
	#Get-Date -Format dd.MM.yyyy | Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object LastBootUpTime 
	
}

function Get-MCPowerDetails {
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
	
	try
	{
		if ($IsLinux)
		{
			$reply = "✅ AC Powered"
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
					$reply = "AC Powered"
				}
				elseif ($percent -ge 95)
				{
					$reply = "Battery $percent% Fully Charged"
				}
				else
				{
					$reply = "Battery ($percent%)"
				}
			}
			else
			{
				# must be offline
				if (($remaining -eq 0) -and ($percent -ge 60))
				{
					$reply = "Battery $percent% full"
				}
				elseif ($remaining -eq 0)
				{
					$reply = "Battery at $percent%"
				}
				elseif ($remaining -le 5)
				{
					$reply = "Battery at $percent% · ONLY $($remaining)min remaining"
				}
				elseif ($remaining -le 30)
				{
					$reply = "Battery at $percent% · only $($remaining)min remaining"
				}
				elseif ($percent -lt 10)
				{
					$reply = "Battery at $percent% · $($remaining)min remaining"
				}
				elseif ($percent -ge 60)
				{
					$reply = "Battery $percent% full · $($remaining)min remaining"
				}
				else
				{
					$reply = "Battery at $percent% · $($remaining)min remaining"
				}
			}
			$powerScheme = (powercfg /getactivescheme)
			$powerScheme = $powerScheme -Replace "^(.*)  \(", ""
			$powerScheme = $powerScheme -Replace "\)$", ""
			$reply += " / Power Scheme '$powerScheme'"
		}
		Write-Output $reply
		
	}
	catch
	{
		"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
		
	}
}

function Get-MCDriveStat {
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
		[string[]]$ComputerName = $env:COMPUTERNAME,
		[Parameter(Position = 1, HelpMessage = "GB is selected by default")]
		[ValidateSet('Bytes', 'KB', 'MB', 'GB')]
		[string]$Capacity = 'GB'
		
	)
	
	
	begin
	{
		Write-Verbose -Message "Starting [$($MyInvocation.Mycommand)]"
		Write-Verbose -Message "Capacity will be expressed in [$Capacity]"
		$Query = "Select * from Win32_LogicalDisk where DriveType='3' and FileSystem='NTFS'"
	}
	
	process
	{
		foreach ($C in $ComputerName)
		{
			Write-Verbose -Message "Processing $c"
			$DriveStat = Get-WMIObject -Query $Query -ComputerName $C
			switch ($Capacity)
			{
				'Bytes' {
					$DriveStat |
					Select-Object -Property @{ name = 'ComputerName'; expression = { $_.SystemName } },
								  DeviceID,
								  VolumeName,
								  Size,
								  FreeSpace,
								  @{ name = 'FreePct'; expression = { [double] ('{0:f2}' -f ($_.FreeSpace / $_.Size * 100)) } }
				}
				
				'KB' {
					$DriveStat |
					Select-Object -Property @{ name = 'ComputerName'; expression = { $_.SystemName } },
								  DeviceID,
								  VolumeName,
								  @{ name = 'SizeKB'; expression = { [double] ('{0:f2}' -f ($_.Size / 1KB)) } },
								  @{ name = 'FreeSpaceKB'; expression = { [double] ('{0:f2}' -f ($_.FreeSpace / 1KB)) } },
								  @{ name = 'FreePct'; expression = { [double] ('{0:f2}' -f ($_.FreeSpace / $_.Size * 100)) } }
				}
				
				'MB' {
					$DriveStat |
					Select-Object -Property @{ name = 'ComputerName'; expression = { $_.SystemName } },
								  DeviceID,
								  VolumeName,
								  @{ name = 'SizeMB'; expression = { [double] ('{0:f2}' -f ($_.Size / 1MB)) } },
								  @{ name = 'FreeSpaceMB'; expression = { [double] ('{0:f2}' -f ($_.FreeSpace / 1MB)) } },
								  @{ name = 'FreePct'; expression = { [double] ('{0:f2}' -f ($_.FreeSpace / $_.Size * 100)) } }
				}
				
				'GB' {
					$DriveStat |
					Select-Object -Property @{ name = 'ComputerName'; expression = { $_.SystemName } },
								  DeviceID,
								  VolumeName,
								  @{ name = 'SizeGB'; expression = { [double] ('{0:f2}' -f ($_.Size / 1GB)) } },
								  @{ name = 'FreeSpaceGB'; expression = { [double] ('{0:f2}' -f ($_.FreeSpace / 1GB)) } },
								  @{ name = 'FreePct'; expression = { [double] ('{0:f2}' -f ($_.FreeSpace / $_.Size * 100)) } }
				}
			}
		}
		
	}
	
	end
	{
		Write-Verbose -Message "Ending [$($MyInvocation.Mycommand)]"
	}
}

function Get-MCAdminRightsStatus {
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
	
	try
	{
		if ($IsLinux)
		{
			# todo
		}
		else
		{
			$user = [Security.Principal.WindowsIdentity]::GetCurrent()
			$principal = (New-Object Security.Principal.WindowsPrincipal $user)
			if ($principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
			{
				"Yes, $dn has Admin Rights."
			}
			elseif ($principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Guest))
			{
				"No, $dn, has Guest Rights Only."
			}
			else
			{
				"No, $dn has Normal User Rights Only."
			}
		}
		
	}
	catch
	{
		"⚠️ Error: $($Error[0]) (in script line $($_.InvocationInfo.ScriptLineNumber))"
		
	}
}

function Get-MCNetwork {
<#
.SYNOPSIS
Displays network adapter information and optionally WiFi profiles with clear text passphrases.
Can be used to determine the most likely candidate for the active Internet-specific network
adapter. Only connected IP adapters are considered; all other adpaters such as tunneling and
loopbacks are ignored.

.PARAMETER Addresses
Return a @(list) of addresses

.PARAMETER Preferred
Only return the preferred network address without report bells and whistles.

.PARAMETER Verbose
Display extra information including MAC addres and bytes sent/received.

.PARAMETER WiFi
Show detailed WiFi profiles include clear text passwords, highlighting
currently active SSID and open networks.

.NOTES
Created:    26/10/2023
Author:     Mark White
Version:    0.0.1
Updated:    
History:    0.0.1 - Initial release
#>
	
	
	
	[CmdletBinding()]
	param (
		[switch]$preferred,
		# just return the preferred address
		[switch]$addresses,
		# return a list of host addresses
		[switch]$wiFi # show detailed WiFi profiles
	)
	
	Begin
	{
		$esc = [char]27
		
		function GetAllAddresses
		{
			$addresses = @()
			if ([Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable())
			{
				[Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | ForEach-Object `
				{
					$props = $_.GetIPProperties()
					
					$address = $props.UnicastAddresses `
					| Where-Object { $_.Address.AddressFamily -eq 'InterNetwork' } `
					| Select-Object -first 1 -ExpandProperty Address
					
					if ($address)
					{
						$addresses += $address.IPAddressToString
					}
				}
			}
			
			$addresses
		}
		
		function GetPreferredAddress
		{
			$prefs = @()
			if ([Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable())
			{
				[Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | ForEach-Object `
				{
					if (($_.NetworkInterfaceType -ne 'Loopback') -and ($_.OperationalStatus -eq 'Up'))
					{
						$props = $_.GetIPProperties()
						
						$address = $props.UnicastAddresses `
						| Where-Object { $_.Address.AddressFamily -eq 'InterNetwork' } `
						| Select-Object -first 1 -ExpandProperty Address
						
						$DNSServer = $props.DnsAddresses `
						| Where-Object { $_.AddressFamily -eq 'InterNetwork' } `
						| Select-Object -first 1 -ExpandProperty IPAddressToString
						
						if ($address -and $DNSServer)
						{
							$prefs += $address.IPAddressToString
						}
					}
				}
			}
			
			if ($prefs.Length -gt 0)
			{
				return $prefs[0]
			}
			
			return $null
		}
		
		function CollectInformation
		{
			$preferred = $null
			$items = @()
			if ([Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable())
			{
				$SSID = $null
				(netsh wlan show interfaces | select-string '\sSSID') -match '\s{2,}:\s(.*)' | Out-Null
				if ($Matches -and $Matches.Count -gt 1)
				{
					$SSID = $Matches[1].ToString()
				}
				
				[Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | ForEach-Object `
				{
					if ($_.NetworkInterfaceType -ne 'Loopback')
					{
						$item = New-Object PSObject -Property @{
							Address		    = $null
							PhysicalAddress = $_.GetPhysicalAddress().ToString()
							DNSServer	    = $null
							Gateway		    = $null
							Description	    = $null
							DnsSuffix	    = $null
							SSID		    = $null
							BytesReceived   = 0
							BytesSent	    = 0
							Status		    = $_.OperationalStatus
							Type		    = $_.NetworkInterfaceType
						}
						
						$props = $_.GetIPProperties()
						
						$item.Address = $props.UnicastAddresses `
						| Where-Object { $_.Address.AddressFamily -eq 'InterNetwork' } `
						| Select-Object -first 1 -ExpandProperty Address
						
						$item.DNSServer = $props.DnsAddresses `
						| Where-Object { $_.AddressFamily -eq 'InterNetwork' } `
						| Select-Object -first 1 -ExpandProperty IPAddressToString
						
						$item.Gateway = $props.GatewayAddresses `
						| Where-Object { $_.Address.AddressFamily -eq 'InterNetwork' } `
						| Select-Object -first 1 -ExpandProperty Address
						
						$stats = $_.GetIPv4Statistics() | Select-Object -first 1
						$item.BytesReceived = $stats.BytesReceived
						$item.BytesSent = $stats.BytesSent
						
						$item.Description = $_.Name + ', ' + $_.Description
						$item.DnsSuffix = $props.DnsSuffix
						if (![String]::IsNullOrWhiteSpace($item.DnsSuffix))
						{
							$item.Description += (', ' + $item.DnsSuffix)
						}
						
						if ($item.Type.ToString().StartsWith('Wireless') -and $SSID -and ($item.BytesReceived -gt 0))
						{
							$item.Description = (', ' + $SSID)
						}
						
						if (($item.Status -eq 'Up') -and $item.Address -and ($item.BytesReceived -gt 0))
						{
							if (!$preferred)
							{
								$preferred = $item
							}
							
							if (!$preffered.SSID)
							{
								$preferred.SSID = $SSID
							}
						}
						
						$items += $item
					}
				}
			}
			
			@{
				Preferred = $preferred
				Items	  = $items
			}
		}
		
		function ShowPreferred
		{
			param ($preferred)
			Write-Host
			if ($null -eq $preferred)
			{
				Write-Host ('{0} Preferred address is unknown' -f $env:COMPUTERNAME) -ForegroundColor DarkGreen -NoNewline
			}
			else
			{
				Write-Host ("{0} Preferred address is {1}" -f $env:COMPUTERNAME, $preferred.Address) -ForegroundColor Green -NoNewline
			}
			
			if ($preferred.SSID)
			{
				Write-Host " | SSID:$($preferred.SSID)" -ForegroundColor DarkGreen -NoNewline
			}
			
			# make FQDN
			$domain = [IPGlobalProperties]::GetIPGlobalProperties().DomainName
			if ([String]::IsNullOrEmpty($domain)) { $domain = [Dns]::GetHostName() }
			$name = [Dns]::GetHostName()
			if ($name -ne $domain) { $name = $name + '.' + $domain }
			Write-Host " | HOST:$name" -ForegroundColor DarkGreen
		}
		
		function GetColorOf
		{
			param ($item,
				$preferred)
			if ($item.Status -ne 'Up') { @{ foregroundcolor = 'DarkGray' } }
			elseif ($item.Address -eq $preferred.Address) { @{ foregroundcolor = 'Green' } }
			elseif ($item.Type -match 'Wireless') { @{ foregroundcolor = 'Cyan' } }
			elseif ($item.Description -match 'Bluetooth') { @{ foregroundcolor = 'DarkCyan' } }
			else { @{ } }
		}
		
		function ShowBasicInfo
		{
			param ($info)
			Write-Host
			Write-Host 'Address         DNS Server      Gateway         Interface'
			Write-Host '-------         ----------      -------         ---------'
			$info.Items | ForEach-Object `
			{
				$line = ("{0,-15} {1,-15} {2,-15} {3}" -f $_.Address, $_.DNSServer, $_.Gateway, $_.Description)
				$hash = GetColorOf $_ $info.Preferred
				Write-Host $line @hash
			}
		}
		
		function ShowDetailedInfo
		{
			param ($info)
			Write-Host
			Write-Host 'IP/DNS/Gateway   Interface Details'
			Write-Host '--------------   -----------------'
			$info.Items | ForEach-Object `
			{
				if ($_.PhysicalAddress)
				{
					for ($i = 10; $i -gt 0; $i -= 2) { $_.PhysicalAddress = $_.PhysicalAddress.insert($i, '-') }
				}
				
				$hash = GetColorOf $_ $info.Preferred
				
				Write-Host ("{0,-15}  {1}" -f $_.Address, $_.Description) @hash
				Write-Host ("{0,-15}  Physical Address.. {1}" -f $_.DNSServer, $_.PhysicalAddress) -ForegroundColor DarkGray
				Write-Host ("{0,-15}  Type.............. {1}" -f $_.Gateway, $_.Type) -ForegroundColor DarkGray
				
				if ($_.Status -eq 'Up')
				{
					Write-Host ("{0,16} Bytes Sent........ {1:N0}" -f '', $_.BytesSent) -ForegroundColor DarkGray
					Write-Host ("{0,16} Bytes Received.... {1:N0}" -f '', $_.BytesReceived) -ForegroundColor DarkGray
					
					if ($_.DnsSuffix)
					{
						Write-Host ("{0,16} DnsSuffix......... {1}" -f '', $_.DnsSuffix) -ForegroundColor DarkGray
					}
				}
				
				Write-Host
			}
		}
		
		function ShowWiFiProfiles
		{
			$path = Join-Path $env:temp 'wxpx'
			if (Test-Path $path)
			{
				Remove-Item $path\*.xml -Force -Confirm:$false
			}
			else
			{
				New-Item -ItemType Directory $path -Force | Out-Null
			}
			
			netsh wlan export profile folder=$path key=clear | Out-Null
			
			$profiles = @()
			Get-Item $path\Wi-Fi-*.xml | ForEach-Object `
			{
				[xml]$xml = Get-Content $_
				$pkg = $xml.WLANProfile
				$key = $pkg.MSM.Security.sharedKey
				if ($key)
				{
					$keyType = $key.keyType
					$protected = $key.protected
					$material = $key.keyMaterial
				}
				else
				{
					$keyType = [String]::Empty
					$protected = [String]::Empty
					$material = [String]::Empty
				}
				
				$profiles += New-Object PSObject -Property @{
					SSID		   = $pkg.SSIDConfig.SSID.name
					Mode		   = $pkg.connectionMode
					Authentication = $pkg.MSM.Security.authEncryption.Authentication
					Encryption	   = $pkg.MSM.Security.authEncryption.encryption
					KeyType	       = $keyType
					Protected	   = $protected
					Material	   = $material
				}
			}
			
			(netsh wlan show interfaces | select-string ' SSID') -match '\s{2,}:\s(.*)' | Out-Null
			$active = $Matches[1].ToString()
			
			Write-Host "`n`nWi-Fi Profiles" -NoNewline -ForegroundColor Green
			Write-Host ", Active:$active" -NoNewline -ForegroundColor DarkGreen
			Write-Host " (netsh wlan delete profile name='NAME')" -ForegroundColor DarkGray
			
			$profiles | `
			Select-Object SSID, Mode, Authentication, Encryption, KeyType, Protected, Material | `
			Format-Table `
						 @{ Label = 'SSID'; Expression = { MakeExpression $_ $_.SSID $active } }, `
						 @{ Label = 'Mode'; Expression = { MakeExpression $_ $_.Mode $active } }, `
						 @{ Label = 'Authentication'; Expression = { MakeExpression $_ $_.Authentication $active } }, `
						 @{ Label = 'Encryption'; Expression = { MakeExpression $_ $_.Encryption $active } }, `
						 @{ Label = 'KeyType'; Expression = { MakeExpression $_ $_.KeyType $active } }, `
						 @{ Label = 'Protected'; Expression = { MakeExpression $_ $_.Protected $active } }, `
						 @{ Label = 'Material'; Expression = { MakeExpression $_ $_.Material $active } } `
						 -AutoSize
			
			Remove-Item $path -Force -Recurse -Confirm:$false
		}
		
		function MakeExpression
		{
			param ($profile,
				$value,
				$active)
			if ($profile.SSID -eq $active) { $color = '92' }
			elseif ($profile.Encryption -eq 'none') { $color = '31' }
			elseif ($profile.Mode -eq 'manual') { $color = '90' }
			else { $color = '97' }
			
			"$esc[$color`m$($value)$esc[0m"
		}
	}
	Process
	{
		if ($preferred)
		{
			return GetPreferredAddress
		}
		
		if ($addresses)
		{
			return GetAllAddresses
		}
		
		$script:verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
		
		$info = CollectInformation
		if ($info -and $info.Items -and $info.Items.Count -gt 0)
		{
			ShowPreferred $info.Preferred
			
			if ($verbose)
			{
				ShowDetailedInfo $info
			}
			else
			{
				ShowBasicInfo $info
			}
		}
		else
		{
			Write-Host 'Network unavailable' -ForegroundColor Red
		}
		
		if ($wiFi)
		{
			ShowWiFiProfiles
		}
	}
	
<#
    ... This is a whole lot less code but is much slower then the code above 

$candidates = @()
Get-NetIPConfiguration | % `
{
    $dns = $_.DNSServer | ? { $_.AddressFamily -eq 2 } | select -property ServerAddresses | select -first 1
    $ifx = $_.InterfaceAlias + ', ' + $_.InterfaceDescription
    if ($_.NetProfile.Name -notmatch 'Unidentified') { $ifx += (', ' + $_.NetProfile.Name) }

    $candidates += New-Object psobject -Property @{
        Address = $_.IPv4Address.IPAddress
        DNSServer = [String]::Join(',', $dns.ServerAddresses)
        Gateway = $_.IPv4DefaultGateway.NextHop
        Interface = $ifx
    }
}
#>
}

function Get-MCOSDetails {
<#
    .SYNOPSIS
        
    .DESCRIPTION

    .PARAMETER ComputerName

    .PARAMETER All

    .NOTES
        Created:    26/10/2023
        Author:     Mark White
        Version:    0.0.1
        Updated:    
        History:    0.0.1 - Initial release

    .EXAMPLE
        
#>
	[CmdletBinding()]
	param (
		[string[]]$ComputerName = $Env:COMPUTERNAME,
		[ValidateSet('Default', 'Dcom', 'Wsman')]
		[string]$Protocol = 'Default',
		[switch]$All
	)
	[string]$Class = 'win32_operatingsystem'
	if ($All)
	{
		[string]$Properties = '*'
	}
	else
	{
		[string[]]$Properties = 'Caption', 'Manufacturer', 'InstallDate', 'OSArchitecture', 'Version', 'SerialNumber', 'BootDevice', 'WindowsDirectory', 'CountryCode', 'OSLanguage', 'OSProductSuite', 'PSComputerName', 'LastBootUpTime', 'LocalDateTime', 'Model'
	}
	$Information = Get-CimData -ComputerName $ComputerName -Protocol $Protocol -Class $Class -Properties $Properties
	if ($All)
	{
		$Information
	}
	else
	{
		foreach ($Info in $Information)
		{
			foreach ($Data in $Info)
			{
				# # Remember to expand if changing properties above
				[PSCustomObject] @{
					ComputerName = if ($Data.PSComputerName) { $Data.PSComputerName } else { $Env:COMPUTERNAME }
					OperatingSystem = $Data.Caption
					OperatingSystemVersion = ConvertTo-OperatingSystem -OperatingSystem $Data.Caption -OperatingSystemVersion $Data.Version
					OperatingSystemBuild = $Data.Version
					Manufacturer = $Data.Manufacturer
					Model = $Data.Model
					OSArchitecture = $Data.OSArchitecture
					OSLanguage   = ConvertFrom-LanguageCode -LanguageCode $Data.OSLanguage
					OSProductSuite = [Microsoft.PowerShell.Commands.OSProductSuite]$($Data.OSProductSuite)
					InstallDate  = $Data.InstallDate
					LastBootUpTime = $Data.LastBootUpTime
					LocalDateTime = $Data.LocalDateTime
					SerialNumber = $Data.SerialNumber
					BootDevice   = $Data.BootDevice
					WindowsDirectory = $Data.WindowsDirectory
					CountryCode  = $Data.CountryCode
				}
			}
		}
	}
}

#endregion Console functions

#region Console variables

$MC_IPv4Address = Get-MCNetwork -preferred
$MC_IPv4Prefix = (Get-MCIPv4Address).PrefixLength
$MC_Manufacturer = (Get-MCOSDetails).Manufacturer
$MC_Model = (Get-MCComputerSystem).Model
$MC_CPUInfo = Get-MCCPUDetails
$MC_PSVersion =
$MC_RAMInfo = Get-MCRAMInfo
$MC_DisplayInfo =
$MC_ExecutionPolicy = Get-ExecutionPolicy
$MC_Greeting = Get-MCGreeting
$MC_UpTime =
$MC_LastBootUpTime =
$MC_PowerInfo = Get-MCPowerDetails
$MC_DriveStatFree =
$MC_DriveStatPct =
$MC_AdminRights =
$MC_OSVersion =
$MC_OSBuild =
$MC_HostName = (Get-MCOSDetails).ComputerName

$Console_TimeToHoliday = Get-MCTimeToHoliday

#endregion Console variables

#region console window dimensions

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

#endregion console window dimensions

#region set console background and text colour

$Shell.BackgroundColor = "Black"
$Shell.ForegroundColor = "White"
if ($isAdmin)
{
	$Shell.BackgroundColor = "Black"
	$Shell.ForegroundColor = "Gray"
}

#endregion set console background and text colour

#region console display pane

# Startscreen / Clear-Host Text
function Write-StartScreen
{
	
	$EmptyConsoleText = @"
                            ____                        ____  _          _ _     
                            |  _ \ _____      _____ _ __/ ___|| |__   ___| | |    
                            | |_) / _ \ \ /\ / / _ \ '__\___ \| '_ \ / _ \ | |    
                            |  __/ (_) \ V  V /  __/ |   ___) | | | |  __/ | |    
                            |_|   \___/ \_/\_/ \___|_|  |____/|_| |_|\___|_|_|    

+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=+
|
|       Greeting                        :       $MC_Greeting
|       Date & Time                     :       $(Get-Date -Format F)
|       Domain \ Username \ Hostname    :       $env:USERDOMAIN \ $env:USERNAME \ $MC_HostName
|       Manufacturer & Model            :       $MC_Manufacturer - $MC_Model
|       Operating System Details        :       $PSConsole_OSVersion ( $PSConsole_OSBuild )
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
|       My Next Holiday is in           >       $PSConsole_TimeToHoliday
|
+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=+

"@
	
	Write-Host -Object $EmptyConsoleText
}

#endregion console display pane

# Overwrite default function "Clear-Host"
function Clear-Host
{
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
function global:prompt
{
	$Success = $?
	
	## Time calculation
	$LastExecutionTimeSpan = if (@(Get-History).Count -gt 0)
	{
		Get-History | Select-Object -Last 1 | ForEach-Object {
			New-TimeSpan -Start $_.StartExecutionTime -End $_.EndExecutionTime
		}
	}
	else
	{
		New-TimeSpan
	}
	
	$LastExecutionShortTime = if ($LastExecutionTimeSpan.Days -gt 0)
	{
		"$($LastExecutionTimeSpan.Days + [Math]::Round($LastExecutionTimeSpan.Hours / 24, 2)) d"
	}
	elseif ($LastExecutionTimeSpan.Hours -gt 0)
	{
		"$($LastExecutionTimeSpan.Hours + [Math]::Round($LastExecutionTimeSpan.Minutes / 60, 2)) h"
	}
	elseif ($LastExecutionTimeSpan.Minutes -gt 0)
	{
		"$($LastExecutionTimeSpan.Minutes + [Math]::Round($LastExecutionTimeSpan.Seconds / 60, 2)) m"
	}
	elseif ($LastExecutionTimeSpan.Seconds -gt 0)
	{
		"$($LastExecutionTimeSpan.Seconds + [Math]::Round($LastExecutionTimeSpan.Milliseconds / 1000, 2)) s"
	}
	elseif ($LastExecutionTimeSpan.Milliseconds -gt 0)
	{
		"$([Math]::Round($LastExecutionTimeSpan.TotalMilliseconds, 2)) ms"
	}
	else
	{
		"0 s"
	}
	
	if ($Success)
	{
		Write-Host -Object "[$LastExecutionShortTime] " -NoNewline -ForegroundColor Green
	}
	else
	{
		Write-Host -Object "! [$LastExecutionShortTime] " -NoNewline -ForegroundColor Red
	}
	
	## History ID
	$HistoryId = $MyInvocation.HistoryId
	# Uncomment below for leading zeros
	# $HistoryId = '{0:d4}' -f $MyInvocation.HistoryId
	Write-Host -Object "$HistoryId`: " -NoNewline -ForegroundColor Cyan
	
	## User
	#$IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
	Write-Host -Object "($(if ($IsAdmin) { ' A ' }
		else { ' U ' })) " -NoNewline -ForegroundColor Yellow
	
	## Path
	$Drive = $pwd.Drive.Name
	$Pwds = $pwd -split "\\" | Where-Object { -Not [String]::IsNullOrEmpty($_) }
	$PwdPath = if ($Pwds.Count -gt 3)
	{
		$ParentFolder = Split-Path -Path (Split-Path -Path $pwd -Parent) -Leaf
		$CurrentFolder = Split-Path -Path $pwd -Leaf
		"..\$ParentFolder\$CurrentFolder"
	}
	elseif ($Pwds.Count -eq 3)
	{
		$ParentFolder = Split-Path -Path (Split-Path -Path $pwd -Parent) -Leaf
		$CurrentFolder = Split-Path -Path $pwd -Leaf
		"$ParentFolder\$CurrentFolder"
	}
	elseif ($Pwds.Count -eq 2)
	{
		Split-Path -Path $pwd -Leaf
	}
	else { "" }
	
	Write-Host -Object "$Drive`:\$PwdPath" -NoNewline -ForegroundColor Magenta
	
	return " > "
}

# Clear Console and show start screen
Clear-Host 