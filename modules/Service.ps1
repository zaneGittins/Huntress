#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress Services Module

.NOTES
    Author: Zane Gittins
#>

param ()

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class Service {
    [string]$Name           = ""
    [string]$DisplayName    = ""
    [string]$State          = ""
    [string]$PathName       = ""
}

function Get-ServiceDetailed {
    [CmdletBinding()]
    param ([Parameter(Mandatory=$true)][array]$Services)

    foreach($Service in $Services) {

        $NewService             = [Service]::new()
        $NewService.Name        = $Service.Name
        $NewService.DisplayName = $Service.DisplayName
        $NewService.State       = $Service.State
        $NewService.PathName    = $Service.PathName
        $global:ReturnData      += $NewService

    }
}

$AllServices = Get-WmiObject win32_service | select Name, DisplayName, State, PathName

Get-ServiceDetailed -Services $AllServices

Return $global:ReturnData
