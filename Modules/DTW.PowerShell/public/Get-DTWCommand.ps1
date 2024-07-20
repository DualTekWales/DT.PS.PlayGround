Function Get-DTWCommand {
<#
   .Notes

#>
    $commands = (Get-Module DTW* | Select-Object ExportedCommands).ExportedCommands
    $commands.Values | Select-Object CommandType,Name,Source
}
New-Alias -Name "DTWCommands" -Value Get-DTWCommand