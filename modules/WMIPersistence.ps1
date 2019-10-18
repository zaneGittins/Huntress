#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress WMIPersistence Module.
    This is a rewrite of PyWMIPersistenceFinder by David Pany from FireEye (@DavidPany) in powershell.
    All credit goes to David Pany for the original implementation. 

.NOTES
    Author: Zane Gittins
    Credits: David Pany -- Mandiant
#>

param ( )

$global:ReturnData = @()

$ObjectsPath = "C:\Windows\System32\wbem\Repository\OBJECTS.DATA"

$ObjectsData = Get-Content $ObjectsPath

$EventConsumerMo = '([\w_]*EventConsumer\.Name\=\")([\w\s]*)(\")'
$EventFilterMo = '(_EventFilter\.Name\=\")([\w\s]*)(\")'

$BindingsDict = @{}
$ConsumerDict = @{}
$FilterDict   = @{}

$ObjectsData = $ObjectsData -split "`n"

$EndDelimeter = 
$Line = $ObjectsData[0..4] -join " "

For ([int]$i=4; $i -le $ObjectsData.Length; $i++) {

        if ($Line -match "_FilterToConsumerBinding") {
        
        $Line -match $EventConsumerMo
        $EventConsumerMatches = $Matches
        
        $Line -match $EventFilterMo
        $EventFilterMatches   = $Matches

        $EventConsumerName = $EventConsumerMatches[0]
        $EventFilterName   = $EventFilterMatches[0]

        Write-Host $EventConsumerName
        Write-Host $EventFilterName

        if($ConsumerDict[$EventConsumerName]) {

        } else {
            $ConsumerDict[$EventConsumerName] = ""
        }

        if($FilterDict[$EventFilterName]) {

        } else {
            $FilterDict[$EventFilterName] = ""
        }

    }

    if($Line -match "CommandLineEventConsumer") {
        $Elements   = ($Line -Match '(CommandLineEventConsumer)(\x00\x00)(.*?)(\x00)(.*?)""({})(\x00\x00)?([^\x00]*)?')
        Write-Host $Matches[7]
        
    }

    $Line = $ObjectsData[($i-4)..$i] -join " "
}

return $global:ReturnData