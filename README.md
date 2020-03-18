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

PowerShell tool to enable blue teams to identify compromised systems and perform triages of important Windows artifacts. This project is similar, and some features are inspired by [Kansa](https://github.com/davehull/Kansa) as well as the SANS FOR508 course. One of the differentiators between Huntress and other projects is that Huntress integrates with LogRhythm to provide SOAR capabilities. All output is in CSV format.

## Requirements

* PowerShell Version >= 5 on hosts and client. Some modules may work on PowerShell < 5, but this is untested.

## Terminology

Huntress can be used to target a single host using the TargetHost parameter, or to target all computers in an OU using TargetOU.

### Modules

Modules are the PowerShell scripts that Huntress executes on remote hosts. Modules must return an array of objects. Modules must be placed in the modules directory.

``` PowerShell
# Running the Connections module against a single host.
.\Huntress.ps1 -TargetHost ExampleComputer -Module .\modules\Connections.ps1
```

Current stable modules include:

* **BAM**: Background Activity Monitor registry parser.
* **Connections**: Current connections on host. Calculates hash of associated PID image path if available.
* **File**: Recursive listing of files and hashes of those files given a top level directory. Checks signature, checks file entropy.
* **LogonEvent**: 4624 events from the Security.evtx log. 
* **Prefetch**: Windows Prefetch for Windows 10 hosts. Currently does not support older operating systems.
* **Process**: Currently running processes, checks signature and calculates hash. Gets command line.
* **RecentDocs**: Recent documents accessed by users of the host.
* **Registry**: Values and subkeys for a given registry key.
* **ScheduledTasks**: Scheduled tasks and actions for those tasks.
* **Service**: Information on currently installed services. State, path to executable (when applicable), display name.
* **StartupPrograms**: Programs that start at boot.
* **WordTrustedDocs**: Word documents trusted by users of the host.
* **EmoCheck**: Detects Emotet using unique way some variants of Emotet generate process name. Based on JPCert's code.

Current development modules include: 

* **WMIPersistence**: Work in progress conversion of PyWMIPersistenceFinder (By FireEye) to PowerShell. This module is not complete.

### Example Usage

```PowerShell
# Dry run to see what hosts the module will run against in the Workstations OU.
.\Huntress.ps1 -TargetOU "CN=Workstations, DC=contoso, DC=com" -Module .\modules\Connections.ps1 -DryRun

# Collecting connections against all hosts in the Workstations OU. Verbose switch to show errors.
.\Huntress.ps1 -TargetOU "CN=Workstations, DC=contoso, DC=com" -Module .\modules\Connections.ps1 -Verbose

# Collecting prefetch data for single host. 
.\Huntress.ps1 -TargetHost ExampleComputer -Module .\modules\Prefetch.ps1
```

### Utilities

``` PowerShell
# Stack data from a CSV file.
.\utils\DataStack.ps1 -File MYCSVFILE.csv -Target MYCOLNAME

# Set a registry key on your local computer so that Get-Credential works via commandline without GUI popup.
.\utils\CredentialCommandline.ps1
```

## Credits

* [Dave Hull](https://github.com/davehull)
* [Rob Lee](https://www.sans.org/course/advanced-incident-response-threat-hunting-training)
* [Eric Zimmerman](https://github.com/EricZimmerman)
* [Michael Leclair](https://digitalforensicsurvivalpodcast.com/2019/11/11/dfsp-195-bam/)
* [Jai Minton](https://www.jaiminton.com/cheatsheet/DFIR/#startup-process-information)
* [Mari DeGrazia](http://az4n6.blogspot.com/2016/02/more-on-trust-records-macros-and.html)