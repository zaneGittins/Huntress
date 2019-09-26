#Requires -Version 5.0

<#
.SYNOPSIS 
    Allows Get-Credential to request credentials via the commandline.

.NOTES
    Author: Zane Gittins
#>

param ()


$Key = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds"
Set-ItemProperty $Key ConsolePrompting True