using module .\private\Vamp\core.psm1
using module .\private\Vamp\prep.psm1
#requires -RunAsAdministrator
#requires -version 5.0

Function vamp(){
<#
.Synopsis
   Simple deployment of PowerShell DSC using YAML.

.DESCRIPTION
   Vamp is a tool aimed at simplifying DSC for developers from all backgrounds.

   The concept is simple - take YAML and turn it into a MOF that will be consumed by the LCM. By doing this we eliminate the need for developers
   to create Configurations scripts in PowerShell to define their configuration but rather a familiar YAML file.

   More Details:

   The first phase of vamp (prep) is preparing the environment to have DSC applied. This will create the meta.mof files for the remote endpoints defined within
   the spec.yml file. Once the files have been created it will issue a Set of the LCM on those nodes to prepare them for the incoming partial configurations in the generate phase.
    
   the prep phase also checks for all the modules that will also be required for the configuration to be sucessful. It will download these modules (psgallery) and push them out
   to the nodes that will require them for their upcoming configuration.

   Vamp will then (in the generate phase) create partial configurations for each of the configurations defined within the .yml file(s) within the core/config directory. 
   It will push these partial configs to the nodes defined within the .spec.yml file.

   once the generate phase has been completed we are simply left with just telling the LCM to run the pending configuration thats been pushed to them.
   This is done during the apply phase.

   All of these switch parameters can be used in conjuction with each other.

.EXAMPLE
   if you run vamp with the -testall parameter it will simply check that the nodes defined within your specfile(s) are available and are able to accept connections via winRM.
   vamp -testall 

.EXAMPLE
   vamp -prep

.EXAMPLE
   vamp -generate -verbose

.EXAMPLE
   vamp -prep -generate -verbose

.EXAMPLE
   vamp -apply -verbose

#>


[CmdletBinding()]
Param(
     [AllowNull()]
     [Switch]$testall,

     [AllowNull()]
     [Switch]$prep,

     [AllowNull()]
     [Switch]$generate,

     [AllowNull()]
     [Switch]$apply
     )

    $ErrorActionPreference = 'Stop'

    #Ensure you're in the root of vamp directory
    if ($pwd.path.Split('\')[-1] -ne 'vamp')
    {
        throw 'Please run vamp from the root of its directory'
    }
    
    #Gather the nodes specified in the spec.yml files
    $Nodes = [VampPrep]::Nodes()

    #Import All private data
    (Get-Childitem .\private\PSYaml\PSYaml.psm1, .\private\Vamp).FullName | Import-Module

    #if the -testall param has been passed
    if ($testall -eq $true)
    {
        #Ensure all nodes are gathered, Test-WSMAN on each remote node.
        $Nodes = [VampPrep]::Nodes()
        foreach ($Node in $Nodes)  
        {
            if ([Bool](Test-WSMan $Node -ErrorAction SilentlyContinue))
            {
              Write-Output "Node $Node is online" 
            }
            else
            {
              Write-Output "Node $Node is OFFLINE" 
            }
        }
    }
    if ($prep -eq $true)
    {
        Write-Output "Starting Prep..."
        Write-Output "Ensuring Nuget is accessable"
        [VampPrep]::BootstrapNuget()

        Write-Output "Finding Required Modules"
        $ToDownload = [VampPrep]::FindModules()

        Write-Output "Downloading Required Modules"
        [VampPrep]::DownloadModules($ToDownload)

        Write-Output "Copying Modules to nodes"
        [VampPrep]::CopyModules($nodes, $ToDownload)

        Write-Output "Applying LCM Configuration to nodes"
        [LCM]::Generate()

        Write-Output 'Prep complete'
    }
    if ($generate -eq $true)
    {
        #Generate all the required mof files and publish them to nodes.
        [MOF]::Compile()
    }
    if ($apply -eq $true)
    {
        #Apply the Configuration to the nodes.
        [MOF]::Apply($Nodes)
    }
}
