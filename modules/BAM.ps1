#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress Background Activity Monitor Module.

.PARAMETER Path
    Optional file path for offline analysis of registry. 

.NOTES
    Author: Zane Gittins
#>

param ( )

$global:ReturnData = @()

$global:BAMPath = ("HKLM\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings")

class BamObject {
    [string]$SID            = ""
    [string]$Path           = ""
    [string]$LastRunTime    = ""
}

function Invoke-GetBam {
    [CmdletBinding()]
    param ()

    $KeyExists = Test-Path Registry::$global:BAMPath
    if($KeyExists -eq $true) {
        $Values = (Get-Item Registry::$global:BAMPath)

            foreach($SubKey in $Values.PSObject.BaseObject.GetSubKeyNames()){
                    
                    foreach($SubKeyValue in $Values.PSObject.BaseObject.OpenSubKey($SubKey).GetValueNames()) {
                        
                        if ($SubKeyValue -match "Device") {
                            $NewBam = [BamObject]::new()
                            $NewBam.SID = $SubKey
                            $NewBam.Path = $SubKeyValue 
                            $data  = $Values.PSObject.BaseObject.OpenSubKey($SubKey).GetValue($SubKeyValue)
                            $time = [DateTime]::FromFileTime( (((((($data[7]*256 + $data[6])*256 + $data[5])*256 + $data[4])*256 + $data[3])*256 + $data[2])*256 + $data[1])*256 + $data[0])
                            $NewBam.LastRunTime = (Get-Date $time -Format "mm-dd-yy hh:mm:ss")
                            $global:ReturnData += $NewBam
                        }
                    }
            }
    }
}

Invoke-GetBam

Return $global:ReturnData