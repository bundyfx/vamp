
Class VampPrep
{
    static [System.String[]] Nodes()
    {
        Import-Module .\private\PSYaml\PSYaml.psm1
        $SpecFiles = [System.IO.DirectoryInfo]::new("$($pwd.Path)\core\spec\").EnumerateFiles()

        [Array]$Nodes += foreach ($File in $SpecFiles)
        {
            [Yaml]::Read($File.Fullname)       
        }
        return $Nodes.nodes.name
    }

    static [void] BootstrapNuget ()
    {
        try 
        {
            Write-Verbose "Making sure the Nuget Package Provider is ready to use"
            Install-PackageProvider Nuget -ForceBootstrap -Force -Confirm:$false -Verbose:$false

            Write-Verbose "Setting PSGallery to be a trusted repository"
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -Verbose:$false
        }
        catch
        {
            throw 'Unable to Install Nuget package provider required for module installation - Error: {0}' -f $PSItem
        }
    }

    static [void] DownloadModules ([PsCustomObject]$SearchScope)
    {
        foreach ($module in $SearchScope)
        {   
            Write-Verbose "Searching the PSGallery for $($module.modulename) - version $($module.moduleversion)"
            try 
            {
                Write-Verbose "Attempting to install $($module.Modulename), version: $($module.moduleversion) from PSGallery"
                Install-Module -Name $module.Modulename -RequiredVersion $module.Moduleversion -Repository PsGallery -Verbose:$false
                Write-Verbose 'Complete'
            }
            catch
            {
                throw "Unable to download $($module.modulename) from the PSGallery - Error: $Psitem"
            }
        }
    }

    static [PsCustomObject] FindModules ()
    {
        try 
        {
            $requiredModules = Get-ChildItem .\core\config\*.yml | 
            ForEach-Object {(ConvertFrom-Yaml -Path $Psitem.FullName).Values} | 
            Select-Object Modulename,ModuleVersion |
            Where-Object {$PsItem.Modulename -ne 'PsDesiredStateConfiguration'} |
            Sort-Object -Unique -Property Modulename  

            Write-Verbose "The required modules for this configuration are: $($requiredModules.modulename -join ', ')"

            return $requiredModules

        }
        catch
        {
            throw 'Error: {0}' -f $Psitem
        }
    }

    static [void] CopyModules($Nodes, $Modules)
    {
        foreach ($node in $nodes.Where{$Psitem -ne $env:COMPUTERNAME -and $Psitem -ne 'localhost'})
        {
            try 
            {
                $CurrentSession = New-PSSession -ComputerName $Node
                foreach ($module in $modules.ModuleName)
                {
                    Write-Verbose "Copying $module to $node" 
                    Copy-Item -Path "C:\Program Files\WindowsPowerShell\Modules\$Module" -ToSession $CurrentSession -Destination "C:\Program Files\WindowsPowerShell\Modules\$Module" -Force -Recurse
                    Write-Verbose "Complete" 
                }
            }
            catch
            {
                throw 'Unable to copy required module files to {0} - Error: {1}' -f $Psitem, $Node
            }
        }
    }
}
