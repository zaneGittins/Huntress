#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress Startup Programs Module

.NOTES
    Author: Zane Gittins
    Credits: Jai Minton (https://www.jaiminton.com/cheatsheet/DFIR/#startup-process-information)
#>

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class StartupProgram {
    [string]$User     = ""
    [string]$Name     = ""
    [string]$Location = ""
    [string]$Command  = ""
    [string]$Hash     = ""
}

$AllStartupPrograms = Get-CimInstance Win32_StartupCommand | Select-Object Name, command, Location, User

foreach($CurrentStartupProgram in $AllStartupPrograms) {

    $NewStartupProgram          = [StartupProgram]::new()
    $NewStartupProgram.User     = $CurrentStartupProgram.User
    $NewStartupProgram.Name     = $CurrentStartupProgram.Name
    $NewStartupProgram.Location = $CurrentStartupProgram.Location
    $NewStartupProgram.Command  = $CurrentStartupProgram.Command
    $NewStartupProgram.Hash     =  (Select-String -InputObject $NewStartupProgram.Command -Pattern "\`"[\w\W]+?\`"" -AllMatches | % { $_.Matches } | % { Get-FileHash $_.Value.Replace("`"","") }).Hash
    $global:ReturnData          += $NewStartupProgram

}

Return $global:ReturnData