#Requires -Version 5.0

<#
.SYNOPSIS
    Huntress is a PowerShell tool to gather forensic data from systems.

.DESCRIPTION 
    Huntress is a tool designed to help blue teams identify compromised systems. Huntress runs PowerShell scripts against groups of machines
    and writes results in CSV format

.PARAMETER Module
    Path to the module to run against the target group. 

.PARAMETER ModuleArguments
    Comma seperated list of arguments to pass to the module.

.PARAMETER TargetOU
    Organizational unit to run module against. 

.PARAMETER TargetHost
    Use a specific host name.

.PARAMETER Credential 
    Pass credential to Huntress.

.PARAMETER Output
    File path to output results to. Default is within results folder.

.PARAMETER DryRun
    Display what hosts Huntress will run against, do not run modules.

.EXAMPLE
 .\Huntress.ps1 -TargetHost MYCOMPUTER -Module .\modules\Connections.ps1 -TargetGroup MYGROUP -Credential $MyCredential

.NOTES
    Author: Zane Gittins
    Last Updated: 3/18/2019
  #>

param (
    [Parameter(Mandatory=$false)][string]$Module,
    [Parameter(Mandatory=$false)][array]$ModuleArguments,
    [Parameter(Mandatory=$false)][string]$TargetOU,
    [Parameter(Mandatory=$false)][string]$TargetHost,
    [Parameter(Mandatory=$false)][System.Management.Automation.PSCredential]$Credential,
    [Parameter(Mandatory=$false)][string]$Output,
    [switch]$DryRun
)

# Only show errors in stdout if in debug mode -- else write to file.
if($PSBoundParameters['Verbose']) { $ErrorActionPreference = "Continue"}
else { $ErrorActionPreference = "SilentlyContinue" }

# Setup file to write all errors to when not in debug mode. 
$global:MyPath     = (Split-Path -Parent $MyInvocation.MyCommand.Definition)
$global:ErrorLog   = $global:MyPath + "\results\errorlog.txt"
$global:Output     = $Output
if(!(Test-Path $global:ErrorLog)) { New-Item -path $global:ErrorLog -type "file"}

function Write-Banner {
    [CmdletBinding()]
    param() 
    $Banner = "
    HUNTRESS                      
             ``ssyo:``
            ``s.  `/y:    
            +.      y+   
    ``.+yy+.+`       -N``
    sNMMMMd-....-://oM/  
  :oyNMMMMmNNmdhhhs//N/  
  +ssyNMMMMMs-.``     y+  
      sMMMMMh:``     ``m:  
      .dNMMMy./-   .ys   
       odMMMN` :o/yy:    
       ``sMMMMs  .o:      
        yNNNNN-          
        `````` "      
                   
    $Details = "`nAuthor: Zane Gittins`n Version Alpha 1.1`n"
    Write-Host $Banner,$Details
}

function Get-ComputerNamesFromOU {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$TargetOU
    )
    $Computers = Get-ADComputer -Filter * -SearchBase $TargetOU
    $ComputerNames = @()
    foreach ($Computer in $Computers) {
        $ComputerNames += ($Computer.Name)
    }
    Return $ComputerNames
}

function Write-ComputerNames {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][array]$Computers
    )
    [int]$count = 0

    foreach($Computer in $Computers) {
        Write-Host $count.ToString()," ",$Computer
        $count += 1
    }
}

function ConvertHuntTo-CSV {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][array]$AllResults,
        [Parameter(Mandatory=$true)][string]$ModulePath
    )
    Try {
        [string]$Module      = (Split-Path $ModulePath -Leaf).Split(".")[0]
        [string]$CSVFolder   = $global:MyPath + "\results" 
        [string]$CSVFileName = $Module + "_" + (Get-Date -Format "MM_dd_yyyy_HHtt").ToString()  + ".csv"
        [string]$CSVPath     = ""
        
        if($global:Output) { $CSVPath = $global:Output } 
        else { $CSVPath = ($CSVFolder + "\" + $CSVFileName) }

        Write-Verbose ("Writing csv to > " + $CSVPath)
        $AllResults | Export-Csv -Path $CSVPath -NoTypeInformation 
    }
    Catch [Exception] {
        Write-Verbose $Error
        Add-Content $global:ErrorLog -Value $Error
        $Error.Clear()
    }
}

function Invoke-Hunt {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][array]$MachineNames,
        [Parameter(Mandatory=$true)][string]$Module,
        [Parameter(Mandatory=$true)][AllowNull()][array]$ModuleArguments,
        [Parameter(Mandatory=$true)][pscredential]$Credential
    )
    if($MachineNames) {
        $AllHunts = Invoke-Command -ComputerName $MachineNames -FilePath $Module -ArgumentList $ModuleArguments -Credential $Credential -AsJob -ErrorAction Ignore
        $AllComplete = $false
        $TotalJobs = $AllHunts.ChildJobs.Count
        while(!$AllComplete) {
            $Done = $true

            $RunningJobs = $TotalJobs
            foreach($ChildHunt in $AllHunts) {
                if($ChildHunt.State -and $ChildHunt.State.ToString() -eq "Running")
                {
                    $Done = $false
                }
                else {
                    $RunningJobs -= 1
                }
            }
            Write-Progress -activity "Running Modules" -status "Progress:" -PercentComplete (($TotalJobs-$RunningJobs)/$TotalJobs*100)
            if($Done) {
                $AllComplete = $true
            }
        }
        $Index = 0
        $AllResults = @()
        foreach($ChildHunt in $AllHunts.ChildJobs) {
            $AllResults += Get-Hunt -ChildJob $ChildHunt -MachineName $MachineNames[$Index]
            $Index += 1
        }
        ConvertHuntTo-CSV -AllResults $AllResults -ModulePath $Module
    }
}

function Get-Hunt {
    [CmdletBinding()]
    param ( 
        [Parameter(Mandatory=$true)]$ChildJob,
        [Parameter(Mandatory=$true)][string]$MachineName
    )
    $Results = Receive-Job $ChildJob
    Return $Results
}

Write-Banner

$AllComputers = @() 

if($PSBoundParameters.ContainsKey("TargetOU") -eq $true -and $TargetOU -ne "" -and $TargetOU -ne $null) {
    $AllComputers = Get-ComputerNamesFromOU $TargetOU
} 
elseif ($PSBoundParameters.ContainsKey("TargetHost") -eq $true) {
    $AllComputers += $TargetHost
}
else {
    Get-Help $MyInvocation.MyCommand.Path
    Write-Host "[-] No TargetOU or TargetHost provided."
    Exit
}

# Only print computer names that Huntress will run against.
if($DryRun) {
    Write-ComputerNames $AllComputers
    Exit
}

# If user provided Module and did not provide ModuleArguments then set variable to null.
if ($PSBoundParameters.ContainsKey('Module') -eq $true -and $PSBoundParameters.ContainsKey('ModuleArguments') -eq $false) {
    $ModuleArguments = $null
} 

# User must pass credentials or enter credentials at run-time.
if($PSBoundParameters.ContainsKey('Credential') -eq $false) { $Credential = Get-Credential }

Write-Host ""

if ($PSBoundParameters.ContainsKey('Module') -eq $true) {
        Write-Host ($Module)," > ",$AllComputers
        Invoke-Hunt -MachineNames $AllComputers -Module $Module -ModuleArguments $ModuleArguments -Credential $Credential 
}
else {
    Get-Help $MyInvocation.MyCommand.Path
    Write-Host "[-] No Module provided."
    Exit
}