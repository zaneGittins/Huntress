#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress Recent Documents Module

.NOTES
    Author: Zane Gittins
    Credits: Jai Minton (https://www.jaiminton.com/cheatsheet/DFIR/#recentdocs-information)
#>

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class RecentDoc {
    [string]$SID       = ""
    [string]$UserName  = ""
    [string]$DocName   = ""
}


function Get-RecentDocs { 
    [CmdletBinding()] param(
        [Parameter(Mandatory=$true)][string]$SID,
        [Parameter(Mandatory=$true)][string]$Username
    )

    $KeyExists = Test-Path "Registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
    if($KeyExists) {
        $RecentDocs = @(); Get-Item -Path "Registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" | Select-Object -ExpandProperty property | ForEach-Object {$i = [System.Text.Encoding]::Unicode.GetString((gp "Registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" -Name $_).$_); $i = $i -replace '[^a-zA-Z0-9 \.\-_\\/()~ ]', '\^'; $RecentDocs += $i.split('\^')[0]};
        foreach($Document in $RecentDocs) {
                $NewRecentDoc          = [RecentDoc]::new()                                                                                                                                                                                   
                $NewRecentDoc.UserName = $Username
                $NewRecentDoc.SID      = $SID
                $NewRecentDoc.DocName  = $Document  
                $global:ReturnData     += $NewRecentDoc  
        }
    }
}

$Users = Get-LocalUser

foreach($User in $Users) {

    Get-RecentDocs -SID $User.SID -Username $User.Name
} 

return $global:ReturnData