![Build status](https://ci.appveyor.com/api/projects/status/s7a7aos4yo2v3vvd?svg=true)

# vamp
A Powershell tool that allows Powershell DSC MOF files to be generated from yaml. 

## Quickstart
* git clone repository
* create your DSC configuration in a .yml file
* edit the vampspec.yml file to contain your target nodes
* Import-Module .\vamp.ps1
* run ```vamp```

## Example 

```yaml
-  service:
    ResourceID : '[Service]bits;'
    name: bits;
    status: Running;
    ensure: present;
    SourceInfo : Service;
    ModuleName : PsDesiredStateConfiguration;
    ModuleVersion : 1.0;

-  service:
    ResourceID : '[Service]W32Time;'
    name: W32Time;
    status: Stopped;
    ensure: present;
    SourceInfo : Service;
    ModuleName : PsDesiredStateConfiguration;
    ModuleVersion : 1.0;
    DependsOn : '[Service]bits;'

-  file:
    ResourceID : '[File]myfile;'
    Type: File;
    Contents : 'Hello world;'
    ensure: present;
    DestinationPath: C:\\temp\\docker\\test.txt;
    ModuleName : PsDesiredStateConfiguration;
    ModuleVersion : 1.0;
    SourceInfo : File;
```
#### Example vampspec.yml
```yaml
-  nodes:
    name : 
     - localhost
     - server1
     - server2
    
```
