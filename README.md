[![Build status](https://ci.appveyor.com/api/projects/status/s7a7aos4yo2v3vvd?svg=true)](https://

# vamp
A Powershell DSC MOF creator that allows MOF files to be generated from yaml. 

## Installation & Setup
Simply git clone this repository, create your DSC configuration in a .yaml file, edit the vampspec.yml file to contain your target nodes and run ```vamp```.

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
