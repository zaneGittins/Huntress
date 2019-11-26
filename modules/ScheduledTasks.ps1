#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress Scheduled Tasks Module - Uses Get-ScheduledTask to get tasks.

.PARAMETER EntropyCiel
    Calculates relative entropy of the action against frequency of characters in the english language. 
    Any results that have a higher relative entropy than this parameter are logged to critical.

.NOTES
    Author: Zane Gittins
    Last Updated: 2/27/2019
#>

param (
    [Parameter(Mandatory=$false, Position=2)][double]$EntropyCiel
)

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class ScheduledTask {
    # ScheduledTask Class.
    [string]$TaskName
    [string]$TaskPath
    [string]$TaskState
    [double]$RelativeEntropy
    [string]$Action
}

function Get-RelativeEntropy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Target 
    )
    [hashtable]$AlphabetHashtable = @{}
    $AlphabetHashtable['E'] = 0.1202
    $AlphabetHashtable['T'] = 0.0910
    $AlphabetHashtable['A'] = 0.0812
    $AlphabetHashtable['O'] = 0.0768
    $AlphabetHashtable['I'] = 0.0731
    $AlphabetHashtable['N'] = 0.0695
    $AlphabetHashtable['S'] = 0.0628
    $AlphabetHashtable['R'] = 0.0602
    $AlphabetHashtable['H'] = 0.0592
    $AlphabetHashtable['D'] = 0.0432
    $AlphabetHashtable['L'] = 0.0398
    $AlphabetHashtable['U'] = 0.0288
    $AlphabetHashtable['C'] = 0.0271
    $AlphabetHashtable['M'] = 0.0261
    $AlphabetHashtable['F'] = 0.0230
    $AlphabetHashtable['Y'] = 0.0211
    $AlphabetHashtable['W'] = 0.0209
    $AlphabetHashtable['G'] = 0.0203
    $AlphabetHashtable['P'] = 0.0182
    $AlphabetHashtable['B'] = 0.0149
    $AlphabetHashtable['V'] = 0.0111
    $AlphabetHashtable['K'] = 0.0069
    $AlphabetHashtable['X'] = 0.0017
    $AlphabetHashtable['Q'] = 0.0011
    $AlphabetHashtable['J'] = 0.0010
    $AlphabetHashtable['Z'] = 0.0007
    $TargetCharArray = $Target.ToUpper().ToCharArray()
    [double]$RelativeEntropy = 0.0
    foreach($Character in $TargetCharArray) {
        if($AlphabetHashtable[$Character.ToString()]) {
            $CharacterCount = ($TargetCharArray | Where-Object {$_ -eq $Character} | Measure-Object).Count
            $CharacterPercent = $CharacterCount / $TargetCharArray.Count
            $RelativeEntropy += ($CharacterPercent * ([System.Math]::Log($CharacterPercent) - [System.Math]::Log($AlphabetHashtable[$Character.ToString()])))
        }
    }
    Return [System.Math]::Round($RelativeEntropy,2)
}

$Objects = Get-ScheduledTask
foreach($Object in $Objects) {

    foreach($Action in $Object.Actions) {

        $NewTask            = [ScheduledTask]::new()
        $NewTask.TaskName   = $Object.TaskName
        $NewTask.TaskPath   = $Object.TaskPath
        $NewTask.TaskState  = $Object.State

        if($Action.Execute) {

            $NewTask.Action             = $Action.Execute
            $RelativeEntropy            = Get-RelativeEntropy $Action.Execute
            $NewTask.RelativeEntropy    = $RelativeEntropy
        }

        $global:ReturnData += $NewTask
    }
}

return $global:ReturnData