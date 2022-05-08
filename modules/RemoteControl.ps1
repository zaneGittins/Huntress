#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress Remote Control Module. Gathers information about the last user that initiated
    an sccm remote control session to this system.

.NOTES
    Author: Zane Gittins
    Last Updated: 05/08/2022
#>

param ()

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class LastConnection {
    [string]$ViewerName
    [string]$ViewerIP
    [string]$ViewerPort
    [string]$LocalIP
    [string]$LocalPort
    [string]$SessionStartTime
    [string]$ControlMode
    [string]$Authentication
}

$SessionStatusKey = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control\SessionStatus"

$NewLastConnection = [LastConnection]::new()
$NewLastConnection.ViewerName = $SessionStatusKey.'Viewer Name'
$NewLastConnection.ViewerIP = $SessionStatusKey.'Viewer IP'
$NewLastConnection.ViewerPort = $SessionStatusKey.'Viewer Port'
$NewLastConnection.LocalIP = $SessionStatusKey.'Local IP'
$NewLastConnection.LocalPort = $SessionStatusKey.'Local Port'
$NewLastConnection.ControlMode = $SessionStatusKey.'Control Mode'
$NewLastConnection.SessionStartTime = $SessionStatusKey.'Session Start Time'
$NewLastConnection.Authentication = $SessionStatusKey.'Authentication'

$global:ReturnData += $NewLastConnection


return $global:ReturnData