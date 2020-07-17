function ConvertFrom-GlobalDateString {
    <#
    .SYNOPSIS
    Converts a text date from certain popular cultures to an object in the local culture.
    #>
    param([string]$Date, $DateOrTimeOrBoth = 'Both')

    $Culture = Get-Culture
    $CultureDateTimeFormat = $Culture.DateTimeFormat
    $DateFormat = $CultureDateTimeFormat.ShortDatePattern
    $TimeFormat = $CultureDateTimeFormat.LongTimePattern
    $fmtDateTime = switch ($DateOrTimeOrBoth) {
        'Date' {$DateFormat} ;
        'Time' {$TimeFormat} ;
        'Both' {"$DateFormat $TimeFormat"} ;
        Default {'Unhandled parameter value'}
    }

    [DateTime]::ParseExact(
        $Date,
        $fmtDateTime,
        [System.Globalization.DateTimeFormatInfo]::InvariantInfo,
        [System.Globalization.DateTimeStyles]::None
    )
}

function Import-AbcUpdateLog {

    [CmdletBinding()]
    param (

        # Path the the log file which contains the output of the ABC-Update.exe command.
        [Parameter(Position=0,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [string]
        $Path = 'C:\Temp\ABC-Update-Install.txt'

    )
    
    begin {

        $ptnSeparatorLine = '^_+?\s*$'
        $ptnNewName = '\-|\s'
        $ptnPatchStatus = '^(.+?)\|'
        $ptnPublishedDate = '.+?\|(.+?)\|'
        $ptnKbNumber = '.+?(KB\d{6,11})\s\|'
        $ptnRevision = '.+?REV\.(\d+?)\s\|'
        $ptnPatchTitle = '.+?REV\.\d+?\s\|(.+)'
        $ptnFinalMessage = 'Finished\s-\s(.+?)$'
        $TextInfo = (Get-Culture).TextInfo

    }
    
    process {

        if (Test-Path $Path) {

            # Different data exists above and below a separator line of underscores (_)
            $LogContent = Get-Content $Path
            $SeparatorLine = $LogContent | Select-String -Pattern $ptnSeparatorLine
            $intSeparatorIndex = ($SeparatorLine.LineNumber) - 1

            # first we parse the metadata about the action being performed into a hashtable
            $strMetaData = $LogContent[0..$intSeparatorIndex] | Where-Object {$_ -match ':\s'}
            $MetaDataHashtable = $strMetaData -replace '\:\s','= ' | ConvertFrom-StringData

            # make sure we have content
            if (! ($MetaDataHashtable.keys) ) {
                echo "No log content: "
                $LogContent
                exit 0
            }

            # now we make an object from the hashtable
            $MetaDataObject = New-Object PSCustomObject
            $MetaDataHashtable.keys | ForEach-Object {

                # Convert the keys to Title case, and remove the spaces and hyphens
                $newName = $TextInfo.totitlecase($_) -replace $ptnNewName

                # use newName for the property name, and add the member with its value to the object
                Try {
                    $MetaDataObject |
                        Add-Member -MemberType NoteProperty -Name $newName -Value ($MetaDataHashtable.$_) -ea Stop
                } Catch {
                    Write-Warning "Hash key converted to '$newName' and threw an error: $($_.Exception.message)"
                }
            }

            # cast any non-string data types properly
            # These are the action list property names
            Try {
                if ($MetaDataObject.Time) {$MetaDataObject.Time =
                    ConvertFrom-GlobalDateString ($MetaDataObject.Time) -ea Stop }
            } Catch {
                $MetaDataObject.Time = (Get-Item $Path -ea 0).LastWriteTime -as [datetime]
            }

            if ($MetaDataObject.UpdateAPIVersion) {$MetaDataObject.UpdateAPIVersion = [version]$MetaDataObject.UpdateAPIVersion}
            if ($MetaDataObject.WindowsUpdateVersion) {$MetaDataObject.WindowsUpdateVersion = [version]$MetaDataObject.WindowsUpdateVersion}
            if ($MetaDataObject.ABCUpdateVersion) {$MetaDataObject.ABCUpdateVersion = [version]$MetaDataObject.ABCUpdateVersion}
            if ($MetaDataObject.MaxReboots) {$MetaDataObject.MaxReboots = [int16]$MetaDataObject.MaxReboots}
            

            # These are the action install property names
            # ????

            # I'm not sure if the Install ones are the same or different, all or some
            # to determine if any keys are unhandled, we keep this hard-coded list of handled keys
            $HandledListKeys = @(
                'Time'
                'Computer Name'
                'Windows version'
                'Reboot request'
                'ABC-Update Version'
                'Windows Update Version'
                'Update API Version'
                'Action'
                'Max reboots'
                'Server Type'
                'Type'
                'Title Include'
                'Query'
            )

            $HandledInstallKeys = @()
            
            $HandledKeys = $HandledListKeys + $HandledInstallKeys

            # We compare to find new keys
            $UnhandledKeys = Compare-Object ($MetaDataHashtable.Keys) ($HandledKeys) |
                Where-Object {$_.SideIndicator -eq '<=='}
            if ($UnhandledKeys) {

                # We warn the console only that there is an issue
                Write-Warning "Unhanlded Key Names exist. They are:"
                Write-Host $UnhandledKeys -f Yellow

            }

            
            # Now parse the text after the separator in an array of patch info
            $postSeparatorContent = $LogContent[($intSeparatorIndex + 1)..($LogContent.count - 1)]
            if ($postSeparatorContent -match '\|') {
                
                # If KB info is found after the separator, make a nested object of KB info
                $KbInfoObject = New-Object System.Collections.ArrayList

                # Parse the KB Info
                $postSeparatorContent | Where-Object {$_ -match '\|'} | ForEach-Object {

                    # Define the values to capture
                    $PatchStatus = [regex]::Match($_,$ptnPatchStatus).Groups[1].Value.Trim() 
                    
                    # cast any non-string data types properly
                    [datetime]
                    $PublishedDate = [regex]::Match($_,$ptnPublishedDate).Groups[1].Value.Trim()
                    
                    $KB = [regex]::Match($_,$ptnKbNumber).Groups[1].Value.Trim()
                    
                    [int]
                    $Revision = [regex]::Match($_,$ptnRevision).Groups[1].Value.Trim()
                    
                    $PatchTitle = [regex]::Match($_,$ptnPatchTitle).Groups[1].Value.Trim()

                    # Add an object to the array
                    [void]($KbInfoObject.Add(
                        [PSCustomObject]@{
                            Status = $PatchStatus
                            PublishedDate = $PublishedDate
                            KB = $KB
                            Revision = $Revision
                            Title = $PatchTitle
                        }
                    ))

                }# $postSeparatorContent | Where-Object {$_ -match '\|'} | ForEach-Object

                
                # Determine if the action performed caused a change in pending reboot status
                $boolRebootFlagged =
                if ($strFinalMessage -eq 'successful, no reboot required') {
                    $false
                } elseif ($strFinalMessage -eq 'successful, reboot required') {
                    $true
                } elseif ($strFinalMessage -eq 'at least one error occurred, no reboot required') {
                    $false
                } elseif ($strFinalMessage -eq 'at least one error occurred, reboot required') {
                    $true
                } else { # Any other case, no reboots needed
                    $false
                }
                # file://tonyp/c$/TP/Utilities/ABC-Update/ABC-Update.pdf pg.18 Return Codes


                # Read the final message
                $strFinalMessage = [regex]::Match($LogContent,$ptnFinalMessage).Groups[1].Value
                

                # Add to the output object
                $MetaDataObject | Add-Member -MemberType NoteProperty -Name 'KbInfo' -Value $KbInfoObject
                $MetaDataObject | Add-Member -MemberType NoteProperty -Name 'RebootFlagged' -Value $boolRebootFlagged
                $MetaDataObject | Add-Member -MemberType NoteProperty -Name 'FinalMessage' -Value $strFinalMessage

            } else {

                # If KB info is NOT found after the separator, read the error message and add it to the object
                $ErrorMessage = @() ; $val = 1
                for ($i = 1; -not [string]::IsNullOrWhiteSpace($val) ; $i++) {

                    # Every line after the separator that isn't null is the error message
                    $val = $LogContent[$intSeparatorIndex + $i].Trim()
                    if (-not [string]::IsNullOrWhiteSpace($val)) {$ErrorMessage += $val}

                }
                $MetaDataObject | Add-Member -MemberType NoteProperty -Name 'ErrorMessage' -Value ($ErrorMessage -join "`n")
                #write-debug 'MetaDataObject' -debug

            }# if ($postSeparatorContent -match '\|')

            # Add to the output object and output to pipeline
            $MetaDataObject | Add-Member -MemberType NoteProperty -Name 'RawContent' -Value ($LogContent -join "`n") -PassThru

        } else {

            Write-Error "Log file ($($Path)) not found on $($env:COMPUTERNAME)"

        }
    }
    
    end {
    
    }

}
