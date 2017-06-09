[![Build status](https://ci.appveyor.com/api/projects/status/s7a7aos4yo2v3vvd/branch/master?svg=true)](https://ci.appveyor.com/project/bundyfx/vamp/branch/master)
# vamp

A tool to simplify PowerShell DSC using YAML

Table of Contents
=================

  * [What and Why?](#what-and-why?)
  * [Get Started](#get-started)
  * [Help](#help)
      * [Config files](#config-files)
      * [Spec files](#spec-files)
  * [Considerations](#Considerations)
  * [To-do](#to-do)


## What and Why?

#### Firstly, What is DSC?

PowerShell Desired State Configuration (DSC) is an essential part of the configuration, management and maintenance of Windows-based servers. It allows a PowerShell script to specify the configuration of the machine using a declarative model in a simple standard way that is easy to maintain and understand.

DSC requires that you create a Configuration Script which, when executed generates a Managed Object Format *(.mof)* file that gets consumed by a nodes Local Configuration Manager *(LCM)*. DSC requires that the user creating the configuration script and the associated configuration data has a solid understanding of the PowerShell syntax and language structure.

### vamp

The purpose of this tool is to simplify DSC and make it more accessible for developers and operators of all backgrounds by abstracting the need for any PowerShell code creation.

*OK, so why make this tool?*

One of the problems I have seen over the last couple of years of using DSC is that: *developers don't know PowerShell*. This is not exactly unexpected when we think of the amount of developers we have in the wild and the odds of knowing PowerShell even at a basic level is mostly down to people with a Windows/.NET background.

However, DSC should *not* be limited to only people with Windows/.NET backgrounds. 

The concept is simple, Take a `.yml` configuration file and transform that in a *hashtable* of data that is then consumed by the LCM on a remote node(s).

## Quick start on Windows 10 (Run as Administrator)

* git clone this repository.
* Make sure your WinRM client is running ```winrm quickconfig```
* From the project root: ```Import-Module vamp.psm1```
* ```vamp -apply example ```

## Detailed (Run As Administrator)

* git clone this repository
* Make sure your WinRM client is running ```winrm quickconfig```
* From the project root: ```Import-Module vamp.psm1```
* create a `spec` yml file. *(see examples)*
* create a `config` yml file. *(see examples)*
* ```vamp -prep nameofspecfile ```
* ```vamp -apply nameofspecfile ```

## Files included in this Repo

All of the `.yml` files in the `spec` and `config` directory can be used as an example, These are not required.

## Help

Omg this is confusing! Help.
Lets break this down to show how simple vamp is to use.

### Commands

#### TestAll

The TestAll switch will simply run the `Test-WSMan` cmdlet against all the nodes defined within your spec file.

This is a simple way to ensure your nodes are listening to incoming connections over WinRM.

In the below example we run the testall functionality against the development spec file.

```PowerShell
vamp -testall development
```

#### Prep

The need for the Prep switch comes from the underlying functionality of Modules in PowerShell. In order to run code from a module we need that module to be stored locally on the node that is executing the code and also in the PowerShell module path.

The Prep switch allows us to grab the required modules that are defined within the configuration files for the defined spec file and download them from the PS Gallery.

This action is only performed on the node in which you're running vamp. Once downloaded, the modules will be pushed to the nodes that require the modules for the upcoming configuration. This step helps take the guess work out of having to manage modules for specific configurations.

```PowerShell
vamp -prep development
```

This would look into the spec file named `development.spec.yml` and find the nodes listed within. Once discovered we can look into the config files that relate to those nodes and download the required modules. Once downloaded we copy them to the nodes that will need them for their upcoming configuration.

#### Apply

This one is simple, *Make it so!*

The Apply switch allows us to apply the configurations for the nodes listed in our spec file.

```PowerShell
vamp -apply development
```

Apply will first call the *test* method of the DSC resource to check that the node is in desired state. If the resource is in desired state then we simply move along to the next resource. If not then we call the *set* method of the resource to apply the changes requested to the node.

### Folder Structure

#### Config Files

Keep your configuration files in the *config* directory. You can keep all your configuration in here *(the root)* or split them up into subfolders that help you make more sense of your environment.

A configuration file is written in standard `.yml` making it easy for everyone to use and adopt. This helps really hit home the main functionality of the tool in that you don't need to write a scrap of PowerShell in order to use PowerShell DSC with vamp.

Lets take a look at an example:

`WebServer.yml`
```
-  WindowsFeature:
    name: Web-Server
    ensure: present
    ModuleName : PsDesiredStateConfiguration
    
-  WindowsFeature:
    name: Web-Asp-Net45
    ensure: present
    ModuleName : PsDesiredStateConfiguration
```

In this example we're configuring a Windows Feature *(Web-Server)* and a Service *(bits)*.

The syntax here is simple. We start off by declaring the name of the resource we would like to use. This can be ANY PowerShell DSC resource.

Then, we access the name property of the DSC resource and pass in the name of the `Windows Feature` and `Service` we want to configure.

We also pass in any other required values for properties in the resource such as `ensure` and `status`. For more information on required parameters for each resource be sure to read the documentation for the module in question.

We also pass in the `ModuleName` for the module in which the resource resides. This is used in both to `Prep` and `Apply` phase of vamp and is required in all vamp configuration files.

There is no limit to the amount of configuration steps you could have in one file. However, to keep things modular it may be easiest to create a set of .yml files needed for your desired configuration.

#### Spec Files

The Spec files are used as guidance for vamp.

We need to know which nodes are going to be applying which configurations. This is where spec file(s) come in. You can have as many as you like to help you organize your environment.

This is a simple way to organize roles and spread them over multiple groups of nodes.

* In the nodes block we can pass in a DNS name or IP Address in order to find our node.
* In the configs block we specify the configs we wish to apply to our nodes. It's `important` that the name of the config match the `.yml` file name in the `config` folder.


`development.spec.yml`
```
-  nodes:
     name:
     - CoolServer02
     - CoolServer03

   configs:
     name:
     - WebServer
     - Firewall_Example
     - Git
```

## Variables

TO DO

## Considerations

* Vamp uses WSMAN to connect to remote nodes. Ensure you are able to connect to the nodes defined within the spec file
* You should have a grasp on how to use YAML. Please see the examples within the config and spec folder.
* When checking for modules the tool will use the standard PS Module path: *C:\Program Files\WindowsPowerShell\Modules*

## To-do

There is always lots to do with this project.

The aim of this project is to simplify DSC to a state that anyone can pick it up and get going.

Here are a couple of things on the to-do list for now:

* Variables
* Alternative method of handling Datatypes from the Yaml configuration. (Currently regex based)
* Refactor codebase to work 100% on PowerShell 6.0
