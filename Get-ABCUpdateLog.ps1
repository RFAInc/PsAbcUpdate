function Get-AbcUpdateLog {
    <#
    .SYNOPSIS
    Parses the log from a previous ABC-Update action.
    .DESCRIPTION
    Given a path to a txt file created by the ABC-Update.exe tool,
    this function will read the information and create a psobject 
    on the pipeline. NOTE: The reboot required state is not a 
    general system status, but a result of the action ABC has taken.
    .PARAMETER Path
    Path the the log file which contains the output of the ABC-Update.exe command.
    #>
    [CmdletBinding()]
    param (
        # Path the the log file which contains the output of the ABC-Update.exe command.
        [Parameter(Position=0)]
        [string]
        $Path = 'C:\Temp\ABC-Update.txt'
    )
    
    begin {
        $ptnKbNumber = '.+?\|.+?(KB\d{6,11})\s\|'
        $ptnRebootRequired = 'Finished\s-\s(.+?)$'
    }
    
    process {
        if (Test-Path $Path) {
            $LogDate = Get-Item $Path | Select-Object -ExpandProperty LastWriteTime
            $LogContent = Get-Content $Path
            $grpKbNumbers = [regex]::Matches($LogContent,$ptnKbNumber).Groups
            $arrKbNumbers = $grpKbNumbers | Foreach-Object {
                if ($_.Length -le 12) {$_.Value}
            }
            $strRebootRequired = 
                [regex]::Match($LogContent,$ptnRebootRequired).Groups[1].Value
            
            # file://tonyp/c$/TP/Utilities/ABC-Update/ABC-Update.pdf pg.18 Return Codes
            $boolRebootRequired =
                if ($strRebootRequired -eq 'successful, no reboot required') {
                    $false
                } elseif ($strRebootRequired -eq 'successful, reboot required') {
                    $true
                } elseif ($strRebootRequired -eq 'at least one error occurred, no reboot required') {
                    $false
                } elseif ($strRebootRequired -eq 'at least one error occurred, reboot required') {
                    $true
                } else { # Any other case, no reboots needed
                    $false
                }
            
            # Create the output object
            New-Object -TypeName PsObject -Property @{
                RebootRequired = $boolRebootRequired
                ResultMessage = $strRebootRequired
                KB = $arrKbNumbers
                LogDate = $LogDate
                RawContent = $LogContent -join "`n"
            }
        } else {
            Write-Output 'Log file not found'
        }
    }
    
    end {
    }
}

