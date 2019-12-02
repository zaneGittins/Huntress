#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress Process Module - Gets running processes using Get-Process.
    Calculates SHA256 hash of image path. Gets authenticode signature of
    image path.

.NOTES
    Author: Zane Gittins
    Last Updated: 11/26/2019
#>

param ()

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class Process {
    [string]$PID                = ""
    [string]$ProcessName        = ""
    [string]$ImagePath          = ""
    [string]$ImageHash          = ""
    [string]$SignatureSubject   = ""
    [string]$SignatureStatus    = ""
    [string]$CommandLine        = ""
}

function Get-ProcessDetailed {
    [CmdletBinding()]
    param ()
    foreach($Process in $global:RunningProcesses) {

        $NewProcess                     = [Process]::new()
        $NewProcess.ProcessName         = $Process.ProcessName
        $NewProcess.PID                 = $Process.ID
        $NewProcess.ImagePath           = $Process.Path
        $NewProcess.ImageHash           = (Get-FileHash $Process.Path).hash
        $Signature                      = (Get-AuthenticodeSignature $Process.Path)
        $NewProcess.SignatureStatus     = $Signature.Status 
        $NewProcess.SignatureSubject    = $Signature.SignerCertificate.Subject
        [int]$SearchID                  = $Process.ID
        $NewProcess.CommandLine         = (Get-WmiObject Win32_Process -Filter "ProcessID = $SearchID" | Select-Object CommandLine).CommandLine
        $global:ReturnData += $NewProcess
    }
}

$global:RunningProcesses = Get-Process

Get-ProcessDetailed

Return $global:ReturnData