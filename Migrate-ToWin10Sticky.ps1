Function Migrate-ToWin10Sticky {

#region Migrate-ToWin10Sticky Function Params
Param(
  [Parameter(Mandatory=$true, Position=0, HelpMessage="Please Provide Asset Tag `nExample: Migrate-ToWin10Sticky -PCwithBackUpFile IS1713922")]
   [string]$PCwithBackUpFile,
	
   [Parameter(Mandatory=$true, Position=1, HelpMessage="Please Provide Asset Tag `nExample: Migrate-ToWin10Sticky -PCwithBackUpFile IS1511410 -destinationWin10PC IS1713922")]
   [string]$destinationWin10PC,

   [Parameter(Mandatory=$true, Position=2, HelpMessage="Please Provide Asset Tag `nExample: Migrate-ToWin10Sticky -PCwithBackUpFile IS1511410 -destinationWin10PC IS1713922 -forUser dobth")]
   [string]$forUser
)
#endregion

#region FilePath Variables
$origPC = "\\$PCwithBackUpFile\c$\ldinst\StickyMigBackUp\ThresholdNotes.snt"
$destPC = "\\$destinationWin10PC\c$\Users\$forUser\AppData\Local\Packages\Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe\LocalState\Legacy\ThresholdNotes.snt"
#endregion

#region Define Functions

#Validate device is online and pinging within Sharp Network.
Function Test-AssetOnline($pc) {
    If ($pc) {
	    If (Test-Connection -ComputerName $pc -Count 2 -BufferSize 16 -Quiet) {
            write-host "Network Status:`n" -BackgroundColor Black -ForegroundColor white
            write-host "$pc is Available `n" -BackgroundColor Green -ForegroundColor white
            Write-Log -Message "$pc Is Available"
            return $true | Out-Null
            } else {
            write-host "`nNetwork Status:" -BackgroundColor Black -ForegroundColor white
            Write-Host "`n$pc Is Offline; Check Network Connection. `n" -BackgroundColor Red -ForegroundColor white
            Write-Log -Level ERROR -Message "$pc OFFLINE"
		    return $false | Out-Null
	    }
    }
    Else {
        return $false
    }
}

#Migrates SNT file from PC containing Win7 SNT Backup to Destination Win10 PC.
Function Copy-SNTFile() {

    If (Test-Path \\$destinationWin10PC\c$\Users\$forUser) {
        try {
            New-Item \\$destinationWin10PC\c$\Users\$forUser\AppData\Local\Packages\Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe\LocalState\Legacy -Type Directory -Force -ErrorAction Stop | Out-Null
            $dirResult = "Created Legacy Dir in LocalState"
        } catch {
            $dirResult = "Failed to Create Legacy Dir in LocalState - $($_.exception.message)"         
        }

        try {
            Copy-Item $origPC $destPC -Force -ErrorAction Stop
            $result = "StickyNotes Migration Completed Successfully on $destinationWin10PC"
            Remove-Item \\$PCwithBackUpFile\c$\ldinst\StickyMigBackUp -Force -Recurse
        } catch {
            $result = "Failed to Migrate Sticky Notes - $($_.exception.message)"
        }

        Write-Host "`n$dirResult`n`n$result`n"
        Write-log -Message $dirResult
        Write-Log -Message $result

        

    } else {
        Write-Host "No profile for $forUser exists on $destinationWin10PC. User needs to log in before migration."
        Write-Log "No profile for $forUser exists on $destinationWin10PC. User needs to log in before migration."
    }

}

#endregion

#region Logging Function ...
Function Write-Log {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $False, HelpMessage = "Log Level")]
		[ValidateSet("INFO", "WARN", "ERROR", "FATAL", "DEBUG")]
		[string]$Level = "INFO",
		[Parameter(Mandatory = $True, Position = 0, HelpMessage = "Message to be written to the log")]
		[string]$Message,
		[Parameter(Mandatory = $False, HelpMessage = "Log file location and name")]
		[string]$Logfile = "\\$PCwithBackUpFile\c$\ldlogs\StickyMig.log"
	)
    BEGIN {
    	$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
	    $Line = "$Stamp $Level $Message`r`n"
    }
    PROCESS {
    	If ($Logfile) {
            [System.IO.File]::AppendAllText($Logfile, $Line)
	    } Else {
		    Write-Output $Line
	    }
    }
    END {}
}
#endregion

#region MAIN
Write-Log -Message "Migrating Sticky Notes BackUp to Destination Win10 Device:"
Test-AssetOnline($PCwithBackUpFile)
Test-AssetOnline($destinationWin10PC)
Copy-SNTFile
#endregion

}
