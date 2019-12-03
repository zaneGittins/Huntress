#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress Scheduled Tasks Module

.NOTES
    Author: Zane Gittins
    Last Updated: 12/3/2019
#>

param (
    [Parameter(Mandatory=$false, Position=2)][double]$EntropyCiel
)

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class ScheduledTask {
    [string]$TaskName
    [string]$TaskPath
    [string]$TaskState
    [string]$Action
}


$Objects = Get-ScheduledTask
foreach($Object in $Objects) {

    foreach($Action in $Object.Actions) {

        $NewTask            = [ScheduledTask]::new()
        $NewTask.TaskName   = $Object.TaskName
        $NewTask.TaskPath   = $Object.TaskPath
        $NewTask.TaskState  = $Object.State

        if($Action.Execute) {

            $NewTask.Action = $Action.Execute
        }

        $global:ReturnData += $NewTask
    }
}

return $global:ReturnData