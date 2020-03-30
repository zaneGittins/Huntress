#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress RDP Login module

.NOTES
    Author: Zane Gittins
#>

param ( )

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class RDPLoginEvent {
    [string]$Timestamp
    [string]$SourceUser
    [string]$SessionID
    [string]$SourceAddress
}

$AllEvents = Get-WinEvent -FilterHashtable @{logname='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational';id=21}

foreach($RDPEvent in $AllEvents) {
    
    $NewEvent               = [RDPLoginEvent]::new()
    $NewEvent.Timestamp     = $RDPEvent.TimeCreated.ToString()
    $NewEvent.SourceUser    = $RDPEvent.Properties[0].Value.ToString()
    $NewEvent.SessionID     = $RDPEvent.Properties[1].Value.ToString()
    $NewEvent.SourceAddress = $RDPEvent.Properties[2].Value.ToString()

    $global:ReturnData += $NewEvent
}

return $global:ReturnData