#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress Sysmon Process Create Module.

.NOTES
    Author: Zane Gittins
#>

param ( )

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class SysmonProcessCreateEvent {
    [string]$Timestamp
    [string]$ProcessGUID
    [int]   $ProcessID
    [string]$Image
    [string]$FileVersion
    [string]$Description
    [string]$Product
    [string]$Company
    [string]$OriginalFileName
    [string]$CommandLine
    [string]$CurrentDirectory
    [string]$User
    [string]$LogonGUID
    [string]$LogonID
    [string]$TerminalSessionID
    [string]$IntegrityLevel
    [string]$MD5
    [string]$SHA256
    [string]$ParentProcessGUID
    [int]   $ParentProcessID
    [string]$ParentImage
    [string]$ParentCommandLine    
}

$AllEvents = Get-winevent -FilterHashtable @{logname='Microsoft-Windows-Sysmon/Operational';id=1}

foreach($SecurityEvent in $AllEvents) {
    
    $NewEvent                       = [SysmonProcessCreateEvent]::new()
    $NewEvent.Timestamp             = $SecurityEvent.Properties[1].Value.ToString()
    $NewEvent.ProcessGUID           = $SecurityEvent.Properties[2].Value.ToString()
    $NewEvent.ProcessID             = $SecurityEvent.properties[3].Value.ToString()
    $NewEvent.Image                 = $SecurityEvent.properties[4].Value.ToString()
    $NewEvent.FileVersion           = $SecurityEvent.properties[5].Value.ToString()
    $NewEvent.Description           = $SecurityEvent.properties[6].Value.ToString()
    $NewEvent.Product               = $SecurityEvent.properties[7].Value.ToString()
    $NewEvent.Company               = $SecurityEvent.properties[8].Value.ToString()
    $NewEvent.OriginalFileName      = $SecurityEvent.properties[9].Value.ToString()
    $NewEvent.CommandLine           = $SecurityEvent.properties[10].Value.ToString()
    $NewEvent.CurrentDirectory      = $SecurityEvent.properties[11].Value.ToString()
    $NewEvent.User                  = $SecurityEvent.properties[12].Value.ToString()
    $NewEvent.LogonGUID             = $SecurityEvent.properties[13].Value.ToString()
    $NewEvent.LogonGUID             = $SecurityEvent.properties[14].Value.ToString()
    $NewEvent.TerminalSessionID     = $SecurityEvent.properties[15].Value.ToString()
    $NewEvent.IntegrityLevel        = $SecurityEvent.properties[16].Value.ToString()
    $NewEvent.MD5                   = $SecurityEvent.properties[17].Value.ToString().Split(",")[0].replace("MD5=","")
    $NewEvent.SHA256                = $SecurityEvent.properties[17].Value.ToString().Split(",")[1].replace("SHA256=","")
    $NewEvent.ParentProcessGUID     = $SecurityEvent.properties[18].Value.ToString()
    $NewEvent.ParentProcessID       = $SecurityEvent.properties[19].Value.ToString()
    $NewEvent.ParentImage           = $SecurityEvent.properties[20].Value.ToString()
    $NewEvent.ParentCommandLine     = $SecurityEvent.properties[21].Value.ToString()

    $global:ReturnData += $NewEvent
}

return $global:ReturnData