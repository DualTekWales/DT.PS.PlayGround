function Format-TableWrapped {
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
    param(
        [Parameter(ValueFromPipeline = $true)]
        [psobject]
        ${InputObject})

    begin {
        $PSBoundParameters['Wrap'] = $true
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Format-Table', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = { & $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    }

    process {
        $steppablePipeline.Process($_)
    }

    end {
        $steppablePipeline.End()
    }
    <#
  .ForwardHelpTargetName Format-Table
  .ForwardHelpCategory Cmdlet
  #>
}