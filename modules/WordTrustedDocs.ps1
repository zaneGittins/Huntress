#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress Word Trusted Documents

.NOTES
    Author: Zane Gittins
    Credits: Mari DeGrazia (http://az4n6.blogspot.com/2016/02/more-on-trust-records-macros-and.html)
#>

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()


class OfficeDocument {
    [string]$Path     = ""
    [string]$Ran      = ""

}

function Get-OfficeTrustedDocs { 
    [CmdletBinding()] param(
        [Parameter(Mandatory=$true)][string]$SID,
        [Parameter(Mandatory=$true)][string]$Username
    )

    $Versions = Get-Item "REGISTRY::HKEY_USERS\$SID\Software\Microsoft\Office"
    foreach($Version in $Versions.GetSubKeyNames()) {
        if($Version -match "[0-9]+\.[0-9]+") { 
            $NewItem = Get-Item "REGISTRY::HKEY_USERS\$SID\SOFTWARE\Microsoft\Office\$Version\Word\Security\Trusted Documents\TrustRecords"
            foreach($Document in $NewItem.Property) {
                $NewOfficeDocument      = [OfficeDocument]::new()
                $NewOfficeDocument.Path = $Document
                $Data                   = $NewItem.GetValue($Document)

                if(($Data[$Data.Length-1] -eq 0x7f) -and  ($Data[$Data.Length-2] -eq 0xff) -and ($Data[$Data.Length-3] -eq 0xff) -and ($Data[$Data.Length-4] -eq 0xff)) {
                    $NewOfficeDocument.Ran = "UserEnabledMacros"
                } else {
                    $NewOfficeDocument.Ran = "UserNotEnabledMacros"
                }
                $global:ReturnData      += $NewOfficeDocument
            }
        }
    }
}

Foreach ($UserProfile in $UserProfiles) {If (($ProfileWasLoaded = Test-Path Registry::HKEY_USERS\$($UserProfile. SID)) -eq $false) {reg load HKU\$($UserProfile.SID) $($UserProfile.UserHive) | echo "Successfully loaded: $($UserProfile.UserHive)"}}
$Users = Get-LocalUser

foreach($User in $Users) {

    Get-OfficeTrustedDocs -SID $User.SID -Username $User.Name
}

Return $global:ReturnData