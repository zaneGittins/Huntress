#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress Connections Module. Gathers current connections, and process information 
    related to those connections.

.NOTES
    Author: Zane Gittins
    Last Updated: 11/26/2019
#>

param ()

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class Connection {
    [string]$RemoteAddress
    [string]$LocalPort
    [string]$State
    [string]$ProcessPID
    [string]$ProcessName
    [string]$ImagePath
    [string]$ImageHash
}

$AllConn = Get-NetTCPConnection

foreach($ConnData in $AllConn) {
    $RemoteAddress                  = $ConnData.RemoteAddress.ToString()
    $LocalPort                      = $ConnData.LocalPort.ToString()
    $OwningProcess                  = $ConnData.OwningProcess.ToString()
    $State                          = $ConnData.State.ToString()
    $NewConnection                  = [Connection]::new()
    $NewConnection.RemoteAddress    = $RemoteAddress
    $NewConnection.LocalPort        = $LocalPort
    $NewConnection.ProcessPID       = $OwningProcess
    $NewConnection.State            = $State
    $Process                        = (Get-Process -PID $OwningProcess)
    $NewConnection.ProcessName      = $Process.Name 
    $NewConnection.ImagePath        = $Process.Path
    $NewConnection.ImageHash        = (Get-FileHash $Process.Path).Hash
    $global:ReturnData += $NewConnection
}

return $global:ReturnData