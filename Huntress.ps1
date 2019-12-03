#Requires -Version 5.0
#Requires -Modules PSWriteColor

<#
.SYNOPSIS
    Huntress is a PowerShell tool to help identify compromised systems. 

.DESCRIPTION 
    Huntress is a tool designed to help blue teams identify compromised systems. Huntress runs PowerShell scripts against groups of machines
    and returns results to tuples based on the severity of it's findings. This makes Huntress easy to extend - All that is required is that your 
    script return a tuple containing three arrays: informational, warning, and critical.

.PARAMETER Quiver
    A newline delimited file containing groups and machine names. Group names should be enclosed in square brackets.

.PARAMETER Module
    Path to the module to run against the target group. 

.PARAMETER ModuleArguments
    Comma seperated list of arguments to pass to the module.

.PARAMETER TargetGroup
    Group to limit the module to. 

.PARAMETER TargetHost
    Use a specific host name, does not require a quiver file. Do not use with TargetGroup or Quiver.

.PARAMETER Credential 
    Pass credential to Huntress.

.PARAMETER CrednetialUsername
    Username to be used with password retrieved from credential file.

.PARAMETER CredentialFile 
    File containing credentials stored as a secure string.

.PARAMETER PrintDebug 
    Print errors to stdout rather than to error file.

.EXAMPLE
 .\Huntress.ps1 -Quiver .\quiver.txt -Module .\modules\Connections.ps1 -TargetGroup MYGROUP -Username MYDOMAIN\myusername -ModuleArguments 127.0.0.1

.EXAMPLE
 .\Huntress.ps1 -Quiver .\quiver.txt -Module .\modules\Registry.ps1 -TargetGroup MYGROUP -Username MYDOMAIN\myusername -ModuleArguments HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run,$null -Info

.EXAMPLE 
  .\Huntress.ps1 -Quiver .\quiver.txt -Module .\modules\Process.ps1 -TargetGroup MYGROUP -Username MYDOMAIN\myusername -ModuleArguments $null,$null,2360
 
.EXAMPLE
  .\Huntress.ps1 -Quiver .\quiver.txt -Module .\modules\File.ps1 -TargetGroup WINDOWS-PRD -Username HAASAUTO\zaneadmin -ModuleArguments C:\Users\tagetusername,EE27DB3652032A3498C54A12407B0CB5

.NOTES
    Author: Zane Gittins
    Last Updated: 11/3/2019
  #>

param (
    [Parameter(Mandatory=$false)][string]$Quiver,
    [Parameter(Mandatory=$false)][string]$Module,
    [Parameter(Mandatory=$false)][array]$ModuleArguments,
    [Parameter(Mandatory=$false)][string]$TargetGroup,
    [Parameter(Mandatory=$false)][string]$TargetHost,
    [Parameter(Mandatory=$false)][System.Management.Automation.PSCredential]$Credential,
    [Parameter(Mandatory=$false)][string]$CredentialUsername,
    [Parameter(Mandatory=$false)][string]$CredentialFile,
    [Switch]$PrintDebug
)

# Only show errors in stdout if in debug mode -- else write to file.
if($PrintDebug) { $ErrorActionPreference = "Continue"}
else { $ErrorActionPreference = "SilentlyContinue" }

# Setup file to write all errors to when not in debug mode. 
$global:MyPath     = (Split-Path -Parent $MyInvocation.MyCommand.Definition)
$global:ErrorLog   = $global:MyPath + "\results\errorlog.txt"
if(!(Test-Path $global:ErrorLog)) { New-Item -path $global:ErrorLog -type "file"}

class MachineGroup {
    [string]$Group
    [array]$Members = @()

    [string]ToString()
    {
        $ToReturn = $this.Group + "`n"
        foreach($Member in $this.Members)
        {
            $ToReturn += ($Member + "`n")
        }
        Return $ToReturn
    }
}

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
                   
    $Details = "`nAuthor: Zane Gittins`n Version Alpha 1.0`n"
    Write-Color -Text $Banner,$Details -Color Blue,DarkBlue
}

function Get-Quiver {
    <# 
        Create MachineGroups and fill with members based on quiver file. 
        Quiver file should be newline delimited. To specify a group enclose the name in square brackets. For Example: [MYGROUP]
        Place machine names under a group. Machine names are allowed to be present in multiple groups.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Quiver
    )
    $QuiverData = Get-Content $Quiver
    $AllGroups = @()
    $CurrentGroup = $null
    foreach ($Line in $QuiverData) {
        if($Line -Match "\[[a-zA-Z0-9\-\ ]+\]") {
            $NewGroup = [MachineGroup]::new()
            $NewGroup.Group = $Line -replace "[\[\]]+"
            $NewGroup.Members = @()
            $AllGroups += $NewGroup
            $CurrentGroup = $NewGroup
        }
        elseif ($Line -Match "[a-zA-Z0-9\-]+") {
            $CurrentGroup.Members += $Line
        }
    }
    Return $AllGroups
}

function Write-Groups {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][array]$Groups
    )
    foreach($Group in $Groups) {
        Write-Color -Text ("`n  " + $Group.Group) -Color Blue
        $count = 1
        foreach($Member in $Group.Members) {
            Write-Color -Text  $count.ToString()," ",$Member -Color Blue,Gray,DarkBlue
            $count += 1
        }
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
        [string]$CSVPath     = ($CSVFolder + "\" + $CSVFileName)

        $AllResults | Export-Csv -Path $CSVPath -NoTypeInformation 
    }
    Catch [Exception] {
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

$AllGroups = @() 

# User must provide either a quiver file or taret host.
if($PSBoundParameters.ContainsKey('Quiver') -eq $true -and $Quiver -ne "" -and $Quiver -ne $null) {
    $AllGroups = Get-Quiver $Quiver

    # User must provide a target group if quiver is specified.
    if($PSBoundParameters.ContainsKey('TargetGroup') -eq $true) {
        $AllGroups = $AllGroups | Where-Object {$_.Group -eq $TargetGroup}
    } else {
        Get-Help $MyInvocation.MyCommand.Path
        Write-Color -Text "Quiver specified but no TargetGroup given." -Color Red
        Exit
    }
} 
elseif ($PSBoundParameters.ContainsKey("TargetHost") -eq $true) {
    $NewGroup = [MachineGroup]::new()
    $NewGroup.Group = "SINGLE"
    $NewGroup.Members = @()
    $NewGroup.Members += $TargetHost
    $AllGroups += $NewGroup
}
else {
    Get-Help $MyInvocation.MyCommand.Path
    Write-Color -Text "No Quiver or TargetHost provided." -Color Red
    Exit
}

# If user provided Module and did not provide ModuleArguments then set variable to null.
if ($PSBoundParameters.ContainsKey('Module') -eq $true -and $PSBoundParameters.ContainsKey('ModuleArguments') -eq $false) {
    $ModuleArguments = $null
} 

# User must pass credentials or enter credentials at run-time.
$LiveCred = $null
if($PSBoundParameters.ContainsKey('Credential') -eq $true) { $LiveCred = $Credential } 
elseif ($PSBoundParameters.ContainsKey('CredentialFile') -eq $true -and $PSBoundParameters.ContainsKey('CredentialUsername')) {
    $Password = Get-Content $CredentialFile | ConvertTo-SecureString
    $LiveCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $CredentialUsername,$Password
}
else {$LiveCred = Get-Credential }

# Display groups that Huntress will run against.
Write-Groups $AllGroups

Write-Host ""

if ($PSBoundParameters.ContainsKey('Module') -eq $true) {
    $Module = $global:MyPath + "\modules\" + $Module
    foreach($Group in $AllGroups) {
        if($Group.Members) {
            Write-Color -Text ($Module)," > ",$Group.Members  -Color Cyan,Gray,DarkBlue
            Invoke-Hunt -MachineNames $Group.Members -Module $Module -ModuleArguments $ModuleArguments -Credential $LiveCred 
        }
    } 
}
else {
    Get-Help $MyInvocation.MyCommand.Path
    Write-Color -Text "No Module provided." -Color Red
    Exit
}