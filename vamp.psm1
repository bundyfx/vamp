#requires -RunAsAdministrator
#requires -version 5.0

using module ./private/vamp/yaml.psm1
using module ./private/vamp/conversion.psm1
using module ./private/vamp/prep.psm1
using module ./private/PSYaml/PSYaml.psm1

<#
.Synopsis
   vamp helps simplify PowerShell DSC by using a well-known, human readable, parsable data serialization language in YAML.
.DESCRIPTION
   See detailed help outlined in Readme.md
.EXAMPLE
   vamp -testall development
.EXAMPLE
   vamp -apply development
.FUNCTIONALITY
   For detailed functionality please see the Readme.md
#>

function vamp(){

  [CmdletBinding()]
  Param(
    #Testall param is used to quickly test that the nodes in a certain spec are listening for WS-MAN connections
    [ValidateNotNullOrEmpty()]
    [Parameter(ParameterSetName='testall')]
    [System.String]$testall,

    #The Prep switch prepares the nodes defined in the passed in spec file with the modules they will need in-order to apply the outlined configuration
    [ValidateNotNullOrEmpty()]
    [Parameter(ParameterSetName='prep')]
    [System.String]$prep,

    #The Apply switch applies the outlined configuration against the defined nodes within the spec file
    [ValidateNotNullOrEmpty()]
    [Parameter(ParameterSetName='apply')]
    [System.String]$apply
    )

    #Stop on any error encountered
    $ErrorActionPreference = 'Stop'

    #Take the data passed in via parameters
    $InputSpec = "$($PSBoundParameters.Values).spec.yml"

    #Gather the data from the spec file name defined in parameter
    $SpecFiles = [System.IO.DirectoryInfo]::new("$PsScriptRoot\spec\").EnumerateFiles().Where{$Psitem.Name -eq $InputSpec}

    #Ensure the spec file exists
    if ($SpecFiles.count -eq 0)
    {
        throw 'Unable to find specfile for {0}' -f $InputSpec
    }

    #Gather all config files listed in the config directory
    $ConfigFiles = [System.IO.DirectoryInfo]::new("$PsScriptRoot\config\").EnumerateFiles()

    #Foreach of the nodes defined within the specfile found - store it into the Nodes array
    [Array]$Nodes += foreach ($File in $SpecFiles)
    {
        #Read the relevant spec file
        [Yaml]::Read($File.Fullname)
    }

    #if the -testall param has been passed
    if ($PSBoundParameters.ContainsKey('testall'))
    {
        #Ensure all nodes are gathered, Test-WSMAN on each remote node.
        foreach ($Node in $Nodes.Nodes.name)
        {
            #If the machine is responding to test-wsman
            if ([Bool](Test-WSMan $Node -ErrorAction SilentlyContinue))
            {
                #Able to make a ws-man connection to the node
                Write-Output "Node $Node is online"
            }
            else
            {
                #Unable to reach the node via WSMAN
                Write-Output "Node $Node is OFFLINE"
            }
        }
    }

    # If Prep param passed in by user
    if ($PSBoundParameters.ContainsKey('prep'))
    {

        #Gather the passed in spec file for preparation
        $InputSpec = [Yaml]::Read($SpecFiles.Fullname)

        #InputSpec Debug
        $InputSpec

        Write-Output "Starting Prep for $($PSBoundParameters.Values)"
        #Sort modules remove duplicates
        $Modules = $InputSpec.configs.name | Sort-Object -Unique

        #Debug
        $Modules

        #Ensure that the user is able to download from the PSGallery - This will make the PSGallery a trusted repository and install the nuget package provider.
        Write-Output "Ensuring Nuget is accessable"
        [VampPrep]::BootstrapNuget()

        Write-Output "Finding Required Modules"

        #Finds all the modules outlined in the configuration files and downloads them locally from the PSGallery.
        $ToDownload = [VampPrep]::FindModules(
        [System.IO.DirectoryInfo]::new("$PsScriptRoot\config\").EnumerateFiles().Where{$Psitem.basename -in $modules}
        )

        $ToDownload

        #Compare the modules installed locally to that of those requested in the configurations
        $CompareModules = [VampPrep]::Compare($ToDownload | Sort-Object -Unique)

        $CompareModules
        #If any modules were passed back from the FindModules method.
        if ($null -ne $CompareModules)
        {
            Write-Output "The required modules for these configuration are that are not already downloaded are: $($CompareModules.Modulename)"

            #Downloads the modules that were returned from the findmodules method.
            Write-Output "Downloading Required Modules"
            [VampPrep]::DownloadModules($CompareModules)
        }
        #else, if no modules passed back - no need to download.
        else
        {
            Write-Output 'No module downloads required for configuration'
        }

        #For each of the nodes for this specific specfile
        foreach($Node in $Nodes.nodes.name)
        {
            #If the node is listening to WS-man connections
            if ([Boolean](Test-WSMan $Node -ErrorAction SilentlyContinue))
            {
                #Copy all the modules to the current node in the foreach loop
                Write-Output "Copying Modules to $Node"
                [VampPrep]::CopyModules($Node, $ToDownload)
            }
            else
            {
                Write-Output "Unable to make a connection to $Node"
            }
        }

        #After all nodes have had modules copied
        Write-Output "Prep Complete"
    }

    #If the user has passed in the apply param
    if ($PSBoundParameters.ContainsKey('apply'))
    {

        #Foreach node within the defined spec
        foreach ($Node in $Nodes.Nodes.Name)
        {
            #If the node is online and listening to WS-MAN
            if ([Boolean](Test-Wsman $Node -ErrorAction SilentlyContinue))
            {
                #Foreach Config from *.yml files that matches the specific node listed in Nodes
                [Array]$Configs = foreach ($File in $ConfigFiles.where{$Psitem.basename -in ($Nodes.where{$Psitem.nodes.name -eq $Node}.configs.name)})
                {
                    #Read the Yaml in for that specific nodes requirements
                    [Yaml]::Read($File.Fullname)
                }

            #Create a session to the node in order to execute our test and set method (Invoke-Command)
            $Session = New-PSSession -ComputerName $Node

            #Foreach of the configurations within the yaml files for this specific node
            foreach ($Config in $Configs)
            {
                #Store the key for the hashtable as string data
                [String]$Name = $Config.Keys

                #Convert whatever data is in the YAML into a hashtable for later splatting into Invoke-DSCResource
                $Props = [Conversion]::ConvertToHash($Config.Values)

                #Store the module name property from the object into its own variable for use in invoke-dscResource
                $Modulename = $Config.values.ModuleName

                #Remove the modulename property from the hashtable as its not valid in the properties param for invoke-dscResource
                $Props.Remove('ModuleName')

                # (This can be majorly improved - used currently for User Resource)
                #If the Username and Password properties are visable in the YAML file
                if ($null -ne $Props.password  -and $null -ne $Props.username)
                {
                    #Create psCredentail Object as required
                    $Props.password = [Conversion]::CreateCredentialObject($Props.username, $Props.password)
                }

                #Invoke our command against the session for the current node
                Invoke-Command -Session $Session -ScriptBlock {

                #Test the configuration against the remote machine (Pass in variables to session with $using:)
                if (-not [Boolean](Invoke-DscResource -Method Test -Name $using:Name -ModuleName $using:Modulename -Property $using:props -Verbose))
                    {
                        #This block will only execute if the Test returned false (meaning its not in desired state and needs to be set)
                        $Output = Invoke-DscResource -Method Set -Name $using:Name -ModuleName $using:Modulename -Property $using:props -Verbose

                        #If the resource made changes that require the be restarted we pass that back to the user
                        Write-Output "Complete - Restart Required: $($Output.RebootRequired)"
                    }
                }
            }

            #Clean up any un-needed sessions
            Remove-PSSession -Computername $Session.Computername
         }
         #If the node is not reachable via WS-MAN
         else
         {
            Write-Output "Unable to connect to $Node"
         }
      }
   }
}
