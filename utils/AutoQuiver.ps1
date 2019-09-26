#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress AutoQuiver Utility - Creates a quiver file based on active directory.

.PARAMETER OutputFile
    File path to output the quiver file to. 

.NOTES
    Author: Zane Gittins
#>

param (
    [Parameter(Mandatory=$true)][string]$OutputFile
)

function Get-QuiverMembers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][array]$QuiverGroups
    )
    [hashtable]$QuiverHashtable = @{}
    $Computers = Get-AdComputer -Filter *
    $Complete = 0
    foreach($Group in $QuiverGroups) {
        Write-Progress -activity "Getting OU Members" -status "Progress:" -PercentComplete (($Complete)/$QuiverGroups.Count*100)
        $GroupMembers = @()
        foreach($Computer in $Computers) {
            if($Computer.DistinguishedName -match ("OU="+$Group)) { $GroupMembers += $Computer.Name }
            }
        $QuiverHashtable[$Group] = $GroupMembers
        $Complete += 1
    }
    Return $QuiverHashtable
}

function Get-QuiverGroups {
    [CmdletBinding()]
    param()
    $QuiverGroups = @()
    $OrganizationalUnits = Get-ADOrganizationalUnit -Filter *
    $Complete = 0
    foreach($OU in $OrganizationalUnits) {
        Write-Progress -activity "Getting Oranizational Units" -status "Progress:" -PercentComplete (($Complete)/$OrganizationalUnits.Count*100)
        $QuiverGroups += $OU.Name
        $Complete += 1
    }
    Return $QuiverGroups
}

function Write-QuiverFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$QuiverHashtable
    )
    $Complete = 0
    foreach($Group in $QuiverHashtable.Keys) {
        Write-Progress -activity "Writing file" -status "Progress:" -PercentComplete (($Complete)/$QuiverHashtable.Count*100)
        Add-Content $OutputFile ("["+$Group+"]`n")
        foreach($Member in $QuiverHashtable[$Group]) {
            if($Member) {
                Add-Content $OutputFile ($Member + "`n")
            }
        }
        Add-Content $OutputFile "`n"
        $Complete += 1
    }
}

$QuiverGroups = Get-QuiverGroups
$QuiverHashtable = Get-QuiverMembers $QuiverGroups
Write-QuiverFile $QuiverHashtable