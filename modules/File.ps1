#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress File Module - Gets all files under a base directory.
    Calculates hashes for all of those files.

.PARAMETER BaseDirectory
    Base directory to recursively search under.

.NOTES
    Author: Zane Gittins
    Last Updated: 11/26/2019
#>

param (
    [Parameter(Mandatory=$true, Position=0)][string]$BaseDirectory
)

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class File {
    [string]$FileName
    [string]$FilePath
    [string]$FileHash
}

function Get-ChildItemDetailed {
    [CmdletBinding()]
    param()

    foreach($Item in $global:FileSearch) {
        if($Item.GetType().ToString() -eq "System.IO.FileInfo" -and [System.IO.File]::Exists($Item.FullName)) {
            $Permission = (Get-Acl $Item.FullName).Access | Where-Object {$_.IdentityReference -match $env:UserName } | Select-Object IdentityReference,FileSystemRights
            if($Permission) {
                $NewFile            = [File]::new()
                $NewFile.FileName   = $Item.Name
                $NewFile.FilePath   = $Item.FullName
                try {
                    $NewFile.FileHash = (Get-FileHash $Item.FullName).Hash
                }
                catch {
                    $NewFile.FileHash = "Failed to calulate."
                }
                $global:ReturnData += $NewFile
            }
        }
    }
}

$global:FileSearch = Get-ChildItem -Path $BaseDirectory -Recurse -ErrorAction SilentlyContinue -Force

Get-ChildItemDetailed

return $global:ReturnData