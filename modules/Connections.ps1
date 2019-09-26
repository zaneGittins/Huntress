#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress Connections Module - Gets current connections using Get-NetTCPConnection

.NOTES
    Author: Zane Gittins
#>

param ( )

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class Connection {
    # Connection Class. Used to store connection data and return to 
    [string]$RemoteAddress
    [string]$LocalPort
    [string]$State
    [string]$OwningProcess

    [string]ToString() {
        Return "REMOTE ADDRESS: " + $this.RemoteAddress.ToString() + " LOCAL PORT: " + $this.LocalPort +  " PID " + $this.OwningProcess + " STATE: " + $this.State
    }
}

$AllConn = Get-NetTCPConnection

foreach($ConnData in $AllConn) {
    $RemoteAddress = $ConnData.RemoteAddress.ToString()
    $LocalPort = $ConnData.LocalPort.ToString()
    $OwningProcess = $ConnData.OwningProcess.ToString()
    $State = $ConnData.State.ToString()
    $NewConnection = [Connection]::new()
    $NewConnection.RemoteAddress = $RemoteAddress
    $NewConnection.LocalPort = $LocalPort
    $NewConnection.OwningProcess = $OwningProcess
    $NewConnection.State = $State
    $global:ReturnData += $NewConnection
}

return $global:ReturnData