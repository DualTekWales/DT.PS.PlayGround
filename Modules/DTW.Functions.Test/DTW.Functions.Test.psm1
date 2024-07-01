
#region Namespaces

using namespace System.IO
using namespace System.Net
using namespace System.Net.NetworkInformation

#endregion Namespaces

#region main private & public function import

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path
$PSModule = $ExecutionContext.SessionState.Module
$PSModuleRoot = $PSModule.ModuleBase

# Dot source public functions
$PublicFunctions = @(Get-ChildItem -Path "$ScriptPath\Public" -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue -Exclude *.Tests.*)

$AllFunctions = $PublicFunctions
foreach ($Function in $AllFunctions) {
	try {
		. $Function.FullName
	}
	catch {
		throw ('Unable to dot source {0}' -f $Function.FullName)
	}
}

Export-ModuleMember -Function $PublicFunctions.BaseName

# Dot source private functions
$PrivateFunctions = @(Get-ChildItem -Path "$ScriptPath\Private" -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue -Exclude *.Tests.*)

foreach ($PrivateFunction in $PrivateFunctions) {
	try {
		. $PrivateFunction.FullName
	}
	catch {
		throw ('Unable to dot source {0}' -f $PrivateFunction.FullName)
	}
}

#endregion main private & public function import