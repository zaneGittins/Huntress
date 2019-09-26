#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress File Module - Gets all files under a base directory.

.PARAMETER BaseDirectory
    Base directory to recursively search under.

.NOTES
    Author: Zane Gittins
#>

param (
    [Parameter(Mandatory=$true, Position=0)][string]$BaseDirectory
)

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class File {
    [string]$Filename
    [string]$Filepath
    [string]$MD5
    [string]ToString() {
        return "FILENAME: " + $this.Filename + " FILEPATH: " + $this.Filepath +  " MD5 " + $this.MD5
    }
}

function Start-FileHunt {
    [CmdletBinding()]
    param()

    foreach($Item in $global:FileSearch) {
        if($Item.GetType().ToString() -eq "System.IO.FileInfo" -and [System.IO.File]::Exists($Item.FullName)) {
            $Permission = (Get-Acl $Item.FullName).Access | Where-Object {$_.IdentityReference -match $env:UserName } | Select-Object IdentityReference,FileSystemRights
            if($Permission) {
                $NewFile = [File]::new()
                $NewFile.Filename = $Item.Name
                $NewFile.Filepath = $Item.FullName
                try {
                    $NewFile.MD5 = (Get-FileHash -Algorithm MD5 $Item.FullName).Hash
                }
                catch {
                    $NewFile.MD5 = "Failed to calulate."
                }
                $global:ReturnData += $NewFile
            }
        }
    }
}

$global:FileSearch = Get-ChildItem -Path $BaseDirectory -Recurse -ErrorAction SilentlyContinue -Force

Start-FileHunt 

return $global:ReturnData