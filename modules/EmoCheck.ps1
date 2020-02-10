#Requires -Version 5.0

<#
.SYNOPSIS 
    Searches for Emotet based on process names. 
    All credit goes to JPCERT from which this PowerShell code was adapted.

.NOTES
    Author: Zane Gittins
    Last Updated: 11/26/2019
    
    Credits 
        1. https://github.com/JPCERTCC/EmoCheck
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

function Get-VolumeSerialNumber {
    [CmdletBinding()]
    param()

    

    $MethodDefinition = @'

      [DllImport("Kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
      [return: MarshalAs(UnmanagedType.Bool)]
      public extern static bool GetVolumeInformation(
        string rootPathName,
        StringBuilder volumeNameBuffer,
        int volumeNameSize,
        out uint volumeSerialNumber,
        out uint maximumComponentLength,
        out FileSystemFeature fileSystemFlags,
        StringBuilder fileSystemNameBuffer,
        int nFileSystemNameSize);

'@

    Add-Type -TypeDefinition @"
    using System;
    using System.Text;
    using System.Diagnostics;
    using System.Runtime.InteropServices;
    using System.Collections.Generic;
    using System.IO;

     
    public static class Kernel32
    {
        [DllImport("kernel32", SetLastError=true, CharSet = CharSet.Ansi)]
        public static extern bool GetVolumeInformation(string Volume, StringBuilder VolumeName, 
        uint VolumeNameSize, out uint SerialNumber, out uint SerialNumberLength, 
        out uint flags, StringBuilder fs, uint fs_size);
    }
     
"@
 
    [ref]$serialnumber = 0
    [ref]$max_componentlen = 0
    [ref]$filesystem_flags = 0
    [string]$volumename

    [Kernel32]::GetVolumeInformation("C:\",
            $null,
            $null,
            $serialnumber,
            $max_componentlen,
            $filesystem_flags,
            $null,
            $null)
    
   return $serialnumber

}

function Get-Word() {
    [CmdletBinding()]
    # std::string keywords, int ptr, int keylen
    param($keywords,
          $ptr,
          $keylen)
    
    [string]$keyword = ""

    For ([int]$i = $ptr; $i -gt 0; $i--) {
        If ($keywords[$i] -ne ',') {
            Continue
        } Else {
            $ptr = $i
            Break
        }
    }
    If ($keywords[$ptr] -eq ',') {
        $ptr++
    }
    For ([int]$i = $ptr; $i -lt $keylen; $i++) {
        If ($keywords[$i] -ne ',') {
            $keyword += $keywords[$i]
            $ptr++
        } Else {
            Break
        }
    }
    return $Keyword;
}

function Get-EmotetProcessName {

    [string]$keywords += "duck,mfidl,targets,ptr,khmer,purge,metrics,acc,inet,msra,symbol,driver,"
    [string]$keywords += "sidebar,restore,msg,volume,cards,shext,query,roam,etw,mexico,basic,url,"
    [string]$keywords += "createa,blb,pal,cors,send,devices,radio,bid,format,thrd,taskmgr,timeout,"
    [string]$keywords += "vmd,ctl,bta,shlp,avi,exce,dbt,pfx,rtp,edge,mult,clr,wmistr,ellipse,vol,"
    [string]$keywords += "cyan,ses,guid,wce,wmp,dvb,elem,channel,space,digital,pdeft,violet,thunk";

    [int]$keylen = $keywords.Length

    # first round
    [uint32]$seed = (Get-VolumeSerialNumber).Value
    [uint32]$q = $seed / $keylen
    [int]$mod = $seed % $keylen

    [string]$keyword += (Get-Word -keywords $keywords -ptr $mod -keylen $keylen)

    # second round
    $mod = (4294967295 - $q) % $keylen
    [string]$keyword += (Get-Word -keywords $keywords -ptr $mod -keylen $keylen)
        
    return $keyword
}


function Get-ProcessDetailed {
    [CmdletBinding()]
    param ([string]$EmotetProcessName)
    foreach($Process in $global:RunningProcesses) {

        if($Process.Path -Match $EmotetProcessName) {
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

            Write-Host $Process.Path
        }
    }
}

[string]$EmotetProcessName = Get-EmotetProcessName

if($EmotetProcessName -ne $null) {
    $global:RunningProcesses = Get-Process
    Get-ProcessDetailed -EmotetProcessName $EmotetProcessName
}

if($global:ReturnData.Length -ge 1) {
    Write-Host "Emotet Detected!"
} 
else {
    Write-Host "No detection."
}

Return $global:ReturnData