![Build status](https://ci.appveyor.com/api/projects/status/s7a7aos4yo2v3vvd?svg=true)

# vamp
A Powershell tool that allows Powershell DSC MOF files to be generated from yaml. 

## Quickstart
* git clone this repository
* create your DSC configuration in a .yml file and place it in configs folder
* edit the vampspec.yml file to contain your target nodes and config names
* Import-Module .\vamp.ps1
* run ```vamp```
* MOF files for the nodes will be generated and placed in project root

## Version

 * 0.1.0 - Released with basic usability (3rd July 2016)
 * 0.1.1 - Added the ability to have multiple config (.yml) files in the config folder which get compiled into a single mof at runtime. (4th July 2016)

## In the works

 * VScode extension for resource snippits
 * The ability vampspec file to hold variables / credentials
 * Integration with PSGallery / Chocolatey to download modules required prior to starting configuration

## Example 

```yaml
-  service:
    ResourceID : '[Service]bits'
    name: bits
    status: Running
    ensure: present
    SourceInfo : Service
    ModuleName : PsDesiredStateConfiguration
    ModuleVersion : 1.0

-  service:
    ResourceID : '[Service]W32Time'
    name: W32Time
    status: Running
    ensure: present
    SourceInfo : Service
    ModuleName : PsDesiredStateConfiguration
    ModuleVersion : 1.0
    DependsOn : '[Service]bits'

-  file:
    ResourceID : '[File]myfile'
    Type: File
    Contents : 'Hello world'
    ensure: present
    DestinationPath: C:\\temp\\helloworld.txt
    ModuleName : PsDesiredStateConfiguration
    ModuleVersion : 1.0
    SourceInfo : File
```

#### Example vampspec.yml
```yaml
-  nodes:
    name : 
     - OVERLORD
     - OVERLORD1
     - OVERLORD2

-  configs:
    name : 
     - example
     - customModules
     - customModulesAdvanced
```
