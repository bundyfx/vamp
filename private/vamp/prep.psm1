<#
A Class with Methods dedicated to the Prep parameter in vamp.
#>

Class VampPrep
{

    #Downloads the Nuget Package Provider
    static [void] BootstrapNuget ()
    {
        #Ensure any errors within this method cause a stop of execution
        $ErrorActionPreference = 'Stop'

        #Attempt to install Nuget and set PsGallery as a trusted repository
        try
        {
            #Nuget Package Provider is required to work with the PSGallery
            Install-PackageProvider Nuget -ForceBootstrap -Force -Confirm:$false -Verbose:$false

            #To ensure that the user is not prompted to confirm the download of modules we set the PSGallery to a trusted repository
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -Verbose:$false
        }
        #If we encounter an error with Installing Nuget or Setting the trusted repository we throw an error
        catch [Exception]
        {
            # throw error to stderr
            throw 'Error: {0}' -f $PSItem
        }
    }

    #Downoads the required modules as defined from Input data
    static [void] DownloadModules ([PsCustomObject]$SearchScope)
    {
        #Foreach of the modules listed in the input data
        foreach ($module in $SearchScope)
        {
            Write-Output "Searching the PSGallery for $($module.modulename)"

            #Try to execute the below scriptblock; if error execute the catch block
            try
            {
                Write-Output "Attempting to install $($module.Modulename) from PSGallery"

                #Attempt to install the module from the PSGallery
                Install-Module -Name $module.Modulename -Repository PsGallery -Verbose:$false -Force -AllowClobber

                Write-Output 'Complete'
            }
            #If any error was encounted in the above script block throw error to stderr
            catch [Exception]
            {
                # Throw error with module name
                throw "Unable to download $($module.modulename) from the PSGallery - Error: $Psitem"
            }
        }
    }

    #Find all required modules from config files
    static [PsCustomObject] FindModules ([System.IO.FileInfo[]]$Files)
    {
        #Attempt to execute the below script block; if any errors occured execute the catch block
        try
        {
            #Foreach File in the passed in File Info object Store into array then return the output to the caller
            [Array]$requiredModules += Foreach ($File in $Files)
            {
                #Store the Value of the converted Yaml into a variable
                $ModuleValues = (ConvertFrom-Yaml -Path $File.FullName).Values

                #From the ModuleValues variable remove dupelicates and PsDesiredStateConfiguration module from yaml data
                $ModuleValues.Where{
                      $Psitem.Modulename -ne 'PsDesiredStateConfiguration'
                    }
            }
            #return the created array object above to the caller
            return $requiredModules | Sort-Object -Unique -Property ModuleName
        }
        #Catch any exceptions that occured
        catch [Exception]
        {
            #throw terminating error and include error message
            throw 'Error: {0}' -f $Psitem
        }
    }

    #Used to compare currently installed modules with proposed downloads
    static [PsCustomObject] Compare([PsCustomObject]$SearchScope)
    {

        #Gather the folders within the default PSModule path (except PsDesiredStateConfiguration which is builtin)
        $currentlyInstalled = [System.IO.DirectoryInfo]::new('C:\Program Files\WindowsPowerShell\Modules').EnumerateDirectories().Where{
            $Psitem.Name -ne 'PsDesiredStateConfiguration'
        }

        #Foreach of the modules within the passed in object
        [Array]$output += foreach ($module in $SearchScope)
        {
            if (-not ($Module.Modulename -in $currentlyInstalled.Basename ))
            {
               #Return just the single (in loop) module if its not currently installed
               $module
            }
        }
        return $output
    }


    #Method that Copies the required Modules to the nodes
    static [void] CopyModules($Nodes, $Modules)
    {
        #Stop if any error is encountered
        $ErrorActionPreference = 'Stop'

        #Foreach node where the input nodes is not the localhost or the localhost omputername or 127.0.0.1
        foreach ($node in $nodes.Where{$Psitem -ne 'localhost'})
        {
            #Attempt the below scriptblock; if any failures occur execute the catch block
            try
            {
                #Create a new PS Session to the remote node in the loop
                $CurrentSession = New-PSSession -ComputerName $Node

                #Foreach of the Modules within the Modules variable
                foreach ($module in $modules.ModuleName)
                {
                    #Execute the Copy of the item to the destination node into the default PS Module path
                    Copy-Item -Path "C:\Program Files\WindowsPowerShell\Modules\$Module" -ToSession $CurrentSession -Destination "C:\Program Files\WindowsPowerShell\Modules\$Module" -Force -Recurse
                }
            }
            #Execute the catch block if any errors were occured within the try block
            catch [Exception]
            {
                #Unable to copy error - throw to stderr
                throw 'Unable to copy required module files to {0} - Error: {1}' -f $Node , $Psitem
            }

            #Remove the un-needed PS Session
            Remove-PSSession -Computername $Node
        }
    }
}
