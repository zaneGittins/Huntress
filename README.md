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

PowerShell tool to help blue teams identify compromised systems. This project is similar, and some features are inspired by [Kansa](https://github.com/davehull/Kansa) as well as SANS FOR508 course.

Differences include: 

* Kansa can push binaries to remote systems for analysis, Huntress does not support this feature at this time.
* Huntress allows for JSON files which allow fine grain tuning of modules.
* Huntress uses a PowerShell script for data stacking.

## Requirements

* Install-Module -Name PSWriteColor
* PowerShell Version >= 5

## Terminology

### Quiver 

The quiver file defines the hosts that Huntress will run against. Group names are arbitrary, but should be chosen meaningfully. Hosts can be present in multiple groups. 

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

* Specify a quiver with -Quiver MyQuiverFile
* Specify a group with -TargetGroup MyGroupName

The utils directory contains a PowerShell script to generate a quiver file from ActiveDirectory.

``` Plaintext
.\utils\AutoQuiver.ps1 -OutputFile autoquiver.txt
```

### Modules

Modules are PowerShell files that return an array of objects.

``` Plaintext

.\Huntress.ps1 -Quiver quiver.txt -TargetGroup Accounting -Module .\modules\Connections.ps1 

```

### Quarry

The quarry file is a json file which specifies modules to run and module parameters. Parameters are passed positionally, therefore it is important to look at the arguments taken by a module when constructing a quarry file.
You can use either a quarry file OR the Module and ModuleArguments parameters, but not both. The examples directory contains several example quarry files.

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

Example of using a Quarry file:

```
.\Huntress.ps1 -Quiver quiver.txt -TargetGroup Accounting -Quarry .\examples\persistence.json
```

## Example Usage

```PowerShell
  # Using a quarry file with console output
  .\Huntress.ps1 -Quiver .\quiver.txt -TargetGroup MYGROUP -Quarry examples\persistence.json

  # Using a quarry file with CSV output
  .\Huntress.ps1 -Quiver .\quiver.txt -TargetGroup MYGROUP -Quarry examples\persistence.json -CSV

  # Pass credentials obtained from Get-Credential
  .\Huntress.ps1 -Quiver .\quiver.txt -TargetGroup MYGROUP -Quarry examples\persistence.json -CSV -Credential $MyCredential

  # Manually running a module
  .\Huntress.ps1 -Quiver .\quiver.txt -TargetGroup MYGROUP -Module modules\Connections.ps1

 ```

## Utilities

``` PowerShell
  # Generate a quiver file using existing Active Directory OUs
  .\utils\AutoQuiver.ps1

  # Stack data from a CSV file.
  .\utils\DataStack.ps1 -File MYCSVFILE.csv -Target MYCOLNAME

  # Set a registry key on your local computer so that Get-Credential works via commandline without GUI output.
  .\utils\CredentialCommandline.ps1

```
