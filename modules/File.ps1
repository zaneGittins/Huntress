#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress File Module - Gets all files under a base directory.
    Calculates hashes for all of those files.

.PARAMETER BaseDirectory
    Base directory to recursively search under.

.NOTES
    Author: Zane Gittins
    Last Updated: 12/3/2019
#>

param (
    [Parameter(Mandatory=$true, Position=0)][string]$BaseDirectory
)

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class File {
    [string]$FileName           = ""
    [string]$FilePath           = ""
    [string]$FileHash           = ""
    [string]$SignatureSubject   = ""
    [string]$SignatureStatus    = ""
    [double]$FileEntropy        = 0
    [string]$FilePacked         = ""

    [void]SetPackedDecision() {

        if($this.FileEntropy -lt 7) {
            $this.FilePacked = "Not Likely"
        }
        elseif($this.FileEntropy -ge 7)
        {
            $this.FilePacked = "Likely"
        }
    }
}

function Get-FileEntropy () {
    [CmdletBinding()]
    param([string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $freq = @(0) * 256

    foreach($byte in $bytes) {
        $freq[[int]$byte] = $freq[[int]$byte] + 1
    }

    [double]$entropy = 0
    For ($i=0; $i -lt $freq.Length; $i++) {
        [double]$div_freq = $freq[$i] / $bytes.Length;
        $entropy += $div_freq * [math]::log($div_freq) / [math]::log(2)
    }

    $entropy *= -1;
    return $entropy
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
                    $NewFile.FileHash       = "Failed to calulate."
                }

                $NewFile.FileEntropy        = Get-FileEntropy -Path $Item.FullName
                $Signature                  = (Get-AuthenticodeSignature $NewFile.FilePath)
                $NewFile.SignatureStatus    = $Signature.Status 
                $NewFile.SignatureSubject   = $Signature.SignerCertificate.Subject

                $NewFile.SetPackedDecision()

                $global:ReturnData          += $NewFile
            }
        }
    }
}

$global:FileSearch = Get-ChildItem -Path $BaseDirectory -Recurse -ErrorAction SilentlyContinue -Force

Get-ChildItemDetailed

return $global:ReturnData