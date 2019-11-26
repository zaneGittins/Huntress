#Requires -Version 5.0

<#
.SYNOPSIS 
    Huntress Prefetch Module - Parses Windows Prefetch Files

.NOTES
    Author: Zane Gittins
    Credits: Eric Zimmerman - C# Code to decompress Windows 10 prefetch file.
#>

param ()

$ErrorActionPreference = "SilentlyContinue"
$global:ReturnData = @()

class PrefetchFile {
    [int]$Version
    [int]$Signature
    [int]$FileSize
    [string]$Filename
    [string]$Hash
    [string]$LastRunTime
}

function Compare-PrefetchHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$FileHex
    )
    $Byte1 = $FileHex.Bytes[0]
    $Byte2 = $FileHex.Bytes[1]
    $Byte3 = $FileHex.Bytes[2]
    $Byte4 = $FileHex.Bytes[3]

    if(($Byte1 -eq 0x4d) -and ($Byte2 -eq 0x41) -and ($Byte3 -eq 0x4d) -and ($Byte4 -eq 0x04)) {
        return $true
    }
    else {
        return $false
    }
}

function Get-PrefetchFilePaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Location
    )

    [array]$FileLocations = @()
    $PrefetchFiles = Get-ChildItem $Location

    foreach($PrefetchFile in $PrefetchFiles) {
        
        $FileData = Get-Content $PrefetchFile.FullName
        $FileData = $FileData | Format-Hex
        if((Compare-PrefetchHeader $FileData) -eq $true) {
            $FileLocations += $PrefetchFile.FullName
        }

    }
    Return $FileLocations
}

function Get-BigEndian {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][array]$LittleEndian
    )
    $ArraySize = $LittleEndian.Length
    $CounterLittle = $ArraySize - 1
    [array]$BigEndian
    while ($CounterLittle -gt 0) {
        $BigEndian += ([byte] $LittleEndian[$CounterLittle-1])
        $BigEndian += ([byte] $LittleEndian[$CounterLittle])
        $CounterLittle -= 2
    }
    Return $BigEndian
 }

 function Get-HexToString {
    param(
        [Parameter(Mandatory=$true)]$Hex
    )
    $Converted = ""
    foreach($Byte in ($Hex)) {
        $Converted += [char][byte]$Byte
    }
    Return $Converted
 }

function Get-PrefetchData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$PrefetchFilePath
    )
    $InputBuffer = [System.IO.File]::ReadAllBytes($PrefetchFilePath)
    [int32]$Size = [bitconverter]::ToUInt32($InputBuffer, 4);

    $MethodDefinition = @'
    // Author: Eric Zimmerman (https://github.com/EricZimmerman) (MIT LICENSE)
    // Minor Modifications: Zane Gittins
    using System;
    using System.Runtime.InteropServices;

    namespace Prefetch.XpressStream
    {
        public class Xpress2
        {
            private const ushort CompressionFormatXpressHuff = 4;
    
            [DllImport("ntdll.dll", CharSet = CharSet.Auto)]
            private static extern uint RtlGetCompressionWorkSpaceSize(ushort compressionFormat,
                ref ulong compressBufferWorkSpaceSize, ref ulong compressFragmentWorkSpaceSize);
    
            [DllImport("ntdll.dll", CharSet = CharSet.Auto)]
            private static extern uint RtlDecompressBufferEx(ushort compressionFormat, byte[] uncompressedBuffer,
                int uncompressedBufferSize, byte[] compressedBuffer, int compressedBufferSize, ref int finalUncompressedSize,
                byte[] workSpace);
    
            public static byte[] Decompress(byte[] buffer, ulong decompressedSize)
            {
                var outBuf = new byte[decompressedSize];
                ulong compressBufferWorkSpaceSize = 0;
                ulong compressFragmentWorkSpaceSize = 0;

                var ret = RtlGetCompressionWorkSpaceSize(CompressionFormatXpressHuff, ref compressBufferWorkSpaceSize,
                    ref compressFragmentWorkSpaceSize);
                if (ret != 0)
                {
                    Console.WriteLine(ret);
                    return null;
                }
                
                var workSpace = new byte[compressFragmentWorkSpaceSize];
                var dstSize = 0;
    
                ret = RtlDecompressBufferEx(CompressionFormatXpressHuff, outBuf, outBuf.Length, buffer, buffer.Length,
                    ref dstSize, workSpace);
                if (ret == 0)
                {
                    return outBuf;
                }
                else
                {
                    Console.WriteLine(ret);
                    return null;
                }
            }
        }
    }
'@
    Add-Type -TypeDefinition $MethodDefinition

    $InputBuffer        = $InputBuffer[8..$InputBuffer.Length]
    $DecompressedData   = [Prefetch.XpressStream.Xpress2]::Decompress($InputBuffer, $Size)
    $PrefetchVersion    = $DecompressedData[0..3]
    $Signature          = $DecompressedData[4..7]
    $FileSize           = $DecompressedData[12..15]
    $ExectuableName     = $DecompressedData[16..59]
    $PrefetchHash       = $DecompressedData[76..79]
    
    # Parse Header Information 
    $PrefetchFile             = [PrefetchFile]::new()
    $PrefetchFile.Version     = [bitconverter]::ToInt32($PrefetchVersion, 0)
    $PrefetchFile.Signature   = [bitconverter]::ToInt32($Signature, 0)
    $PrefetchFile.FileSize    = [bitconverter]::ToInt32($FileSize, 0)
    $PrefetchFile.Filename    = ((Get-HexToString $ExectuableName) -replace "\W","")
    $PrefetchFile.Hash        = (Get-BigEndian $PrefetchHash).ToString()

    # Parse Prefetch File.
    switch($PrefetchFile.Version) {
        # Windows XP, 2003
        17 {
            break
        }
        # Windows Vista, 7
        23 {
            break
        }
        # Windows 8.1
        26 {
            break
        }
        # Windows 10
        30 {
            $Filetime = $DecompressedData[128..191]
            $Counter = 0
            [array]$RunTimeArray = @() 
            while($Counter -lt 8) {
                [int64]$FileTimeConverted   = [int64][bitconverter]::ToInt64($Filetime, ($Counter * 8))
                $NewRunTime                 =  ([System.DateTimeOffset]::FromFileTime(($FileTimeConverted)))
                $RunTimeArray               += $NewRunTime
                $Counter                    += 1
            }
            $PrefetchFile.LastRunTime   = $RunTimeArray[0]
            break
        }
    }

    Return $PrefetchFile
}

$PrefetchFilePaths = Get-PrefetchFilePaths "C:\Windows\Prefetch"
foreach($PrefetchFilePath in $PrefetchFilePaths) {

    $PrefetchData = Get-PrefetchData $PrefetchFilePath 
    $global:ReturnData += $PrefetchData

}

Return $global:ReturnData