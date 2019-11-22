# Huntress

```PowerShell
             `ssyo:`
            `s.  /y:
            +.      y+
    `.+yy+.+       -N`
    sNMMMMd-....-://oM/  
  :oyNMMMMmNNmdhhhs//N/  
  +ssyNMMMMMs-.`     y+  
      sMMMMMh:`     `m:  
      .dNMMMy./-   .ys
       odMMMN :o/yy:
       `sMMMMs  .o:
        yNNNNN-
```

PowerShell tool to enable blue teams to identify compromised systems and perform triages of important Windows artifacts. This project is similar, and some features are inspired by [Kansa](https://github.com/davehull/Kansa) as well as the SANS FOR508 course. One of the differentiators between Huntress and other projects is that Huntress integrates with LogRhythm to provide SOAR capabilities.

## Requirements

* Install-Module -Name PSWriteColor
* PowerShell Version >= 5

## Terminology

Huntress can be run in many ways. 

* Against a single host.
* Against multiple hosts.
* With a single module.
* Running multiple modules.
* With commandline output.
* With CSV output.

### Quiver 

A text file called a quiver file is defined when running Huntress against multiple hosts. The text file should be newline delimited, and should specifiy group names and host names. Group names are arbitrary, but should be chosen meaningfully. Hosts can be present in multiple groups. For easy generation of a quiver file you can use the script AutoQuiver.ps1 provided in the utils directory to generate a quiver file based on AD OUs. 

Quiver Syntax Example:

``` Plaintext
[GROUP-NAME1]
HOST1
HOST2
...
HOSTN

[GROUP-NAME2]
HOST1
HOST2
...
HOSTN
```

Example Quiver usage:

``` PowerShell
# Collecting credentials against all hosts in the target group.
.\Huntress.ps1 -Quiver .\quiver.txt -TargetGroup MYGROUP -Module Connections.ps1
```

Example AutoQuiver usage:

``` Plaintext
.\utils\AutoQuiver.ps1 -OutputFile quiver.txt
```

### Modules

Modules are the PowerShell scripts that Huntress executes on remote hosts. Modules must return an array of objects. Modules must be placed in the modules directory.

``` PowerShell
# Running the Connections module against a single host.
.\Huntress.ps1 -TargetHost TARGETHOST -Module Connections.ps1
```

Current stable modules include:

* BAM: Background Activity Monitor registry parser.
* Connections: Current connections on host.
* File: Recursive listing of files and hashes of those files given a top level directory.
* LogonEvent: 4624 events from the Security.evtx log. 
* Prefetch: Windows Prefetch for Windows 10 hosts. Currently does not support older operating systems.
* Registry: Values and subkeys for a given registry key.
* ScheduledTasks: Scheduled tasks and actions for those tasks.
* Service: Information on currently installed services. State, path to executable (when applicable), display name.

Current development modules include: 

* WMIPersistence: Work in progress conversion of PyWMIPersistenceFinder (By FireEye) to PowerShell. This module is not complete.

### Quarry

A quarry file is used to run multiple modules against a host or group of hosts in the same invocation. The quarry file is in json format and specifies modules to run and module parameters. Parameters are passed positionally, therefore it is important to look at the arguments taken by a module when constructing a quarry file.

Example Quarry File:

``` JSON
{
    "modules\\MyModule.ps1":
    {
        "Parameter1":[],
        "Parameter2": []
    },
    "modules\\MyModule2.ps1":
    {
        "Parameter1":[],
        "Parameter2": []
    }
}
```

Example Quarry Usage:

``` PowerShell
# Hunting for persistence against all hosts in the Accounting group.
.\Huntress.ps1 -Quiver quiver.txt -TargetGroup Accounting -Quarry .\examples\persistence.json
```

### Example Usage

```PowerShell
# Collecting credentials against all hosts in the target group.
.\Huntress.ps1 -Quiver .\quiver.txt -TargetGroup MYGROUP -Module Connections.ps1

# Collecting active connections for a single host. 
.\Huntress.ps1 -TargetHost TARGETHOST -Module Connections.ps1

# Using a quarry file with CSV output
.\Huntress.ps1 -Quiver .\quiver.txt -TargetGroup MYGROUP -Quarry examples\persistence.json -CSV

# Pass credentials obtained from Get-Credential
.\Huntress.ps1 -Quiver .\quiver.txt -TargetGroup MYGROUP -Quarry examples\persistence.json -CSV -Credential $MyCredential
```

### Utilities

``` PowerShell
# Generate a quiver file using existing Active Directory OUs
.\utils\AutoQuiver.ps1

# Stack data from a CSV file.
.\utils\DataStack.ps1 -File MYCSVFILE.csv -Target MYCOLNAME

# Set a registry key on your local computer so that Get-Credential works via commandline without GUI popup.
.\utils\CredentialCommandline.ps1
```

## Creating and Running a LogRhythm SmartResponse with Huntress

This repository contains a folder named "huntress\_smart\_response" from this folder you can create a LogRhythm LPI, which can be imported into LogRhythm to allow LogRhythm to run Huntress as a SmartResponse. Follow these steps to allow LogRhythm to run Huntress as a SmartResponse:

* Create a smart response directory C:\Smart-Response
* Clone Huntress to C:\Smart-Response\Huntress
* Create an LPI from the huntress\_smart\_response folder.
* Import the LPI into LogRhythm. 
* Encrypt LogRhythm AD credentials and save to disk, LogRhythm will pass these to Huntress to run scripts on remote hosts. Since LogRhythm runs SmartResponse under the SYSTEM user, it is necessary to generate a secure string as SYSTEM. One way to create these credentials is to use the sysinternals tool psexec.

``` PowerShell
psexec -s powershell.exe
Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File "C:\LogRhythm-Cred.txt"
```
* Results of LogRhythm SmartResponse are saved to C:\Smart-Response\Huntress\results