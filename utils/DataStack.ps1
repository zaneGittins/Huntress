#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress DataStack

.PARAMETER File
    File path to csv file to stack.

.PARAMETER Target
    Variable to stack

.NOTES
    Author: Zane Gittins
#>

param (
    [Parameter(Mandatory=$true)][string]$File,
    [Parameter(Mandatory=$true)][string]$Target
)

class DataStack {
    [string]$Name
    [int]$Count
}

$CSVData = Import-Csv -Path $File
$Stacked=@{}
foreach($row in $CSVData)
{
    $Value = $row.$Target
    if ($Stacked[$Value]) { $Stacked[$Value] = ($Stacked[$Value] + 1) }
    else {$Stacked[$Value] = 1}
}

$StackedArray=@()
foreach($key in $Stacked.Keys) {

    $NewStack = [DataStack]::new()
    $NewStack.Name  = $key
    $NewStack.Count = $Stacked[$key]
    $StackedArray   += $NewStack
}

$ExportPath = $Target + "_STACKED_" + (Split-Path $File -Leaf)
$StackedArray | Export-CSV -Path $ExportPath -NoTypeInformation 