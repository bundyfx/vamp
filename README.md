![Build status](https://ci.appveyor.com/api/projects/status/s7a7aos4yo2v3vvd?svg=true)

# vamp
A Powershell tool that allows Powershell DSC MOF files to be generated from yaml. 

## Quickstart
* git clone this repository
* create your DSC configuration in a .yml file and place it in configs folder
* edit the vampspec.yml file to contain your target nodes and config names
* Import-Module .\vamp.psm1
* run ```vamp -?```

## Parameters

* prep
  - The 'prep' switch parameter calls the vamp tool to gather to required modules from the configuration .yml files in the configs directory. Once gathered it will then attemp to download
  those modules from the PSGallery and copy them out to any of the nodes that will require them for the upcoming configuration.

* apply
  - The 'apply' switch parameters calls the vamp tool to generate the mof files required for the configuration defined within the .yml files residing in the configs directory.
  Once the .mof files have been generated they will then be applied to the nodes.

## Version

 * 0.1.0 - Released with basic usability (3rd July 2016)
 * 0.1.1 - Added the ability to have multiple config (.yml) files in the config folder which get compiled into a single mof at runtime. (4th July 2016)
 * 0.1.2 - Reworked the way the Yaml file works - More composite based now in that multiple nodes can be specified and multiple configs for multiple nodes (See examples). (7th July 2016) 

## In the works

 * VScode extension for resource snippits.
 * See Issues tab for other upcoming changes.


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
