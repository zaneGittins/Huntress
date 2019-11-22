#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress Registry Module.

.PARAMETER RegKey
    Registry key to get values for.

.NOTES
    Author: Zane Gittins
#>

param (
    [Parameter(Mandatory=$true, Position=0)][array]$RegKeys
)

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class RegistryKey {
    [string]$RegKey = ""
    [string]$Value  = ""

    [string]ToString() {
        $ToReturn = "REG-KEY[" + $this.Exists.ToString() + "]: " + $this.RegKey + " = " + $this.Value
        Return $ToReturn
    }
}

function Get-Key {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][string]$RegKey
    )
    $KeyExists = Test-Path Registry::$RegKey
    if($KeyExists -eq $true) {
        $Values = (Get-Item Registry::$RegKey)
        $Values.PSObject | ForEach-Object { 
            foreach($string in $_.BaseObject.Property) {
                    $NewKey            = [RegistryKey]::new()
                    $NewKey.RegKey     = $RegKey 
                    $NewKey.Value      = $_.BaseObject.GetValue($string)
                    $global:ReturnData += $NewKey
                } 
            }
    }
}

if($PSBoundParameters.ContainsKey('RegKeys') -eq $true -And $RegKeys) {
    foreach($RegKey in $RegKeys) { Get-Key -RegKey $RegKey }
}

Return $global:ReturnData