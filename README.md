[![Build status](https://ci.appveyor.com/api/projects/status/s7a7aos4yo2v3vvd/branch/master?svg=true)](https://ci.appveyor.com/project/bundyfx/vamp/branch/master)
# vamp

A tool to simplify PowerShell DSC

Table of Contents
=================

  * [What and Why?](#what-and-why?)
  * [Resources](#resources)
  * [Get Started](#get-started)
  * [Help](#help)
  * [Considerations](#Considerations)

## What and Why?

Why the hell did I make this?

## Resources

You can use any DSC resource you wish with vamp. Here are a few basic ones to get your started.

| Resource      | Module  | Documentation |
| ------------- | ------- | ------------- |
| Archive     | PsDesiredStateConfiguration | [Link](https://msdn.microsoft.com/en-us/powershell/dsc/archiveresource) |
| Environment      |   PsDesiredStateConfiguration | [Link](https://msdn.microsoft.com/en-us/powershell/dsc/environmentresource) |
| File      | PsDesiredStateConfiguration | [Link](https://msdn.microsoft.com/en-us/powershell/dsc/fileresource) |
| Group      |   PsDesiredStateConfiguration | [Link](https://msdn.microsoft.com/en-us/powershell/dsc/groupresource) |
| Log      | PsDesiredStateConfiguration | [Link](https://msdn.microsoft.com/en-us/powershell/dsc/logresource) |
| Package      |   PsDesiredStateConfiguration | [Link](https://msdn.microsoft.com/en-us/powershell/dsc/packageresource) |
| Registry      | PsDesiredStateConfiguration | [Link](https://msdn.microsoft.com/en-us/powershell/dsc/registryresource) |
| Script     |   PsDesiredStateConfiguration | [Link](https://msdn.microsoft.com/en-us/powershell/dsc/scriptresource) |
| Service      | PsDesiredStateConfiguration | [Link](https://msdn.microsoft.com/en-us/powershell/dsc/serviceresource) |
| User     |   PsDesiredStateConfiguration | [Link](https://msdn.microsoft.com/en-us/powershell/dsc/userresource) |
| WindowsFeature      | PsDesiredStateConfiguration | [Link](https://msdn.microsoft.com/en-us/powershell/dsc/windowsfeatureresource) |
| WindowsProcess      |   PsDesiredStateConfiguration | [Link](https://msdn.microsoft.com/en-us/powershell/dsc/windowsprocessresource) |

## Get started

* git clone this repository.
* create a `spec` yml file. *(see examples)*
* create a `config` yml file. *(see examples)*
* From the project root: ```Import-Module vamp.psm1```
* ```vamp -prep```
* ```vamp -apply```

## Help

Omg this is confusing! Help.
Lets break this down to show how simple vamp is.

### Commands

#### TestAll

What does TestAll do?

The TestAll switch will simply run the `Test-WSMan` cmdlet against all the nodes defined within your spec file.

This is a simple way to ensure your nodes are listening to incoming connections over WinRM.

#### Prep

The need for the Prep switch comes from the underlying functionality of Modules in PowerShell. In order to run code from a module we need that module to be located locally on the node that is executing the code in the PowerShell module path.

The Prep switch allows us to grab the required modules that are defined within the configuration files and download them from the PS Gallery.

This action is only performed on the node in which you're running vamp from. Once downloaded the modules will be pushed to the nodes that require the modules for the upcoming configuration.

#### Apply

This one is simple, Make it so!

The Apply switch allows us to apply the configurations defined within the *.yml* files within the *config* to our nodes defined within the *spec.yml* file.

Apply will first call the *test* method of the DSC resource to check that the node is in desired state. If the resource is in desired state then we simply move along to the next resource. If not then we call the *set* method of the resource to apply the changes requested to the node.

### Folder Structure

#### Configuration Files

We keep our configuration files in the *config* directory. You can keep all your configuration in here in the root or split them up into subfolders that help you make more sense of your environment.

A configuration file is written in standard `.yml` making it wasy for everyone to use and adopt. This helps really hit home the main functionality of the tool in that you dont need to write a scrap of PowerShell in order to use PowerShell DSC.

Lets take a look at an example:

```yaml
-  WindowsFeature:
    name: Web-Server
    ensure: present
    ModuleName : PsDesiredStateConfiguration

-  Service:
    name: bits
    status: running
    ensure: present
    ModuleName : PsDesiredStateConfiguration
```

In this example we're configuring a Windows Feature *(Web-Server)* and a Service *(bits)*.

The syntax here is simple. We start off by declaring the name of the resource we would like to use. This can be ANY PowerShell DSC resource.

Then, we access the name property of the DSC resource and pass in the name of the `Windows Feature` and `Service` we want to configure.

We also pass in any other required values for properties in the resource such as `ensure` and `status`. For more information on required parameters for each resource be sure to read the documentation for the module in question.

We also pass in the `ModuleName` for the module in which the resource resides. This is used in both to `Prep` and `Apply` phase of vamp and is required in all vamp configuration files.

#### Spec Files

The Spec files are used as guidance for vamp.

We need to know which nodes are going to be applying which configurations. This is where spec file(s) come in. You can have as many as you like to help you organize your environment. You can also *(see below)* group in multiple blocks of `nodes` and `configs` into the same `.yml` file.

This is a simple way to organize roles and spread them over multiple groups of nodes.

* In the nodes block we can pass in a DNS name or IP Address in order to find our node.
* In the configs block we specify the configs we wish to apply to our nodes. It's `important` that the name of the config match the `.yml` file name in the `config` folder.


```yaml
-  nodes:
    name :
     - localhost
     - CoolServer01

   configs:
    name :
     - Example
     - MoreExamples
     - Firewall_Example
     - NodeJS

-  nodes:
    name :
     - CoolServer02
     - CoolServer03

   configs:
    name :
     - WebServer
     - Firewall_Example
     - Git
```


## Considerations

Considerations, things to think about.

### Credentials

How to work with Credentials?

### Remote Connectivity

How this works with remote connectivity?
