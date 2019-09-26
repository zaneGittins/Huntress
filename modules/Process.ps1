#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress Process Module - Gets running processes using Get-Process.

.NOTES
    Author: Zane Gittins
    Last Updated: 3/13/2019
#>

param ()

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class Process {
    [string]$ProcessName = ""
    [string]$ImagePath = ""
    [string]$PID = ""

    [string]ToString() {
        $ToReturn = "PID: " + $this.PID + " PROCESS NAME: " + $this.ProcessName + " IMAGE PATH: " + $this.ImagePath
        Return $ToReturn
    }
}

function Hunt-Processes {
    [CmdletBinding()]
    param ()
    foreach($Process in $global:RunningProcesses) {
        $NewProcess = [Process]::new()
        $NewProcess.ProcessName = $Process.ProcessName
        $NewProcess.PID = $Process.ID
        $NewProcess.ImagePath = $Process.Path
        $global:ReturnData += $NewProcess
    }
}

$global:RunningProcesses = Get-Process

Hunt-Processes

Return $global:ReturnData
