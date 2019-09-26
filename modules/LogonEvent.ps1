#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress LogonEvent Module.

.NOTES
    Author: Zane Gittins
#>

param ( )

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class EventData {
    [string]$EventID
    [string]$TimeCreated

    [string]$AccountNameDest
    [string]$AccountDomainDest

    [string]$LogonType           

    [string]$SID                    
    [string]$AccountNameSource      
    [string]$AccountDomainSource    
    
    [string]$ProcessNameSource      

    [string]$NetworkAddressSource   
    [string]$NetworkPortSource      
}

$AllEvents = Get-winevent -FilterHashtable @{logname='security'; id=4624;}

foreach($SecurityEvent in $AllEvents) {
    
    $NewEvent                       = [EventData]::new()
    $NewEvent.EventID               = $SecurityEvent.ID.ToString()
    $NewEvent.TimeCreated           = $SecurityEvent.TimeCreated.ToString()
    $NewEvent.AccountNameDest       = $SecurityEvent.properties[1].Value.ToString()
    $NewEvent.AccountDomainDest     = $SecurityEvent.properties[2].Value.ToString()
    $NewEvent.LogonType             = $SecurityEvent.properties[8].Value.ToString()
    $NewEvent.SID                   = $SecurityEvent.properties[4].Value.ToString()
    $NewEvent.AccountNameSource     = $SecurityEvent.properties[5].Value.ToString()
    $NewEvent.AccountDomainSource   = $SecurityEvent.properties[6].Value.ToString()
    $NewEvent.ProcessNameSource     = $SecurityEvent.properties[17].Value.ToString()
    $NewEvent.NetworkAddressSource  = $SecurityEvent.properties[18].Value.ToString()
    $NewEvent.NetworkPortSource     = $SecurityEvent.properties[19].Value.ToString()

    $global:ReturnData += $NewEvent
}

return $global:ReturnData