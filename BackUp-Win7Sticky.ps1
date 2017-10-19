Function Backup-Win7Sticky {

#region Backup-Win7Sticky Function Params
Param(
  [Parameter(Mandatory=$true, Position=0, HelpMessage="Please Provide Asset Tag `nExample: Backup-Win7Sticky -originatingPC IS1713922")]
   [string]$originatingPC,
	
   [Parameter(Mandatory=$true, Position=1, HelpMessage="Please Provide Asset Tag `nExample: Backup-Win7Sticky -originatingPC IS1511410 -destinationPC IS1713922")]
   [string]$destinationPC,

   [Parameter(Mandatory=$true, Position=2, HelpMessage="Please Provide Asset Tag `nExample: Backup-Win7Sticky -originatingPC IS1511410 -destinationPC IS1713922 -forUser dobth")]
   [string]$forUser
)
#endregion

#region FilePath Variables
$origPC = "\\$originatingPC\c$\Users\$forUser\AppData\Roaming\Microsoft\Sticky Notes\StickyNotes.snt"
$destPC = "\\$destinationPC\c$\LDinst\StickyMigBackUp\ThresholdNotes.snt"
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

#Migrates SNT file from Originating Win7 PC to Interim PC for temporary storage.
Function Copy-SNTFile() {

    If (Test-Path \\$originatingPC\c$\Users\$forUser) {
        try {
            New-Item \\$destinationPC\c$\LDinst\StickyMigBackUp -Type Directory -Force -ErrorAction Stop | Out-Null
            $dirResult = "Created StickyMigBackUp Dir in LDlogs"
        } catch {
            $dirResult = "Failed to Created StickyMigBackUp Dir in LDlogs - $($_.exception.message)"         
        }

        try {
            Copy-Item $origPC $destPC -Force -ErrorAction Stop
            $result = "StickyNotes BackedUp Successfully to $destinationPC"
        } catch {
            $result = "Failed to back up Sticky Notes - $($_.exception.message)"
        }

        Write-Host "`n$dirResult`n`n$result`n"
        Write-log -Message $dirResult
        Write-Log -Message $result

    } else {
        Write-Host "No profile for $forUser exists on $originatingPC."
        Write-Log "No profile for $forUser exists on $originatingPC. "
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
		[string]$Logfile = "\\$destinationPC\c$\ldlogs\StickyMig.log"
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
Write-Log -Message "Backing Up Win7 Sticky Notes:"
Test-AssetOnline($originatingPC)
Test-AssetOnline($destinationPC)
Copy-SNTFile
#endregion

}
