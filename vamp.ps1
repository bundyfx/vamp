#requires -RunAsAdministrator
#requires -version 5.0
Class Vamp {

static [PsCustomObject] ReadYaml([System.String]$Path)
{
    try 
    {
        
        $Reader = ConvertFrom-Yaml -Path $Path -As Hash
        return $Reader
    }
    catch
    {
        throw 'Unable to read Yaml - Error: {0} ' -f $Psitem
    }
}

static [void] ImportPSYaml ()
{
    try 
    {
        Import-Module $PSScriptRoot\private\PSYaml\PSYaml.psm1
    }
    catch
    {
        throw 'Unable to Import PSYaml Module - Error: {0}' -f $Psitem
    }
}

static [void] BootstrapNuget ()
{
    try 
    {
        Install-PackageProvider Nuget -ForceBootstrap -Force -Confirm:$false -Verbose:$false #Make method
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
            Install-Module -Name $module.Modulename -RequiredVersion $module.Moduleversion -Repository PsGallery -Verbose
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
        $requiredModules = Get-ChildItem $PSScriptRoot\configs\*.yml | 
        ForEach-Object {(ConvertFrom-Yaml -Path $Psitem.FullName).Values} | 
        Select-Object Modulename,ModuleVersion |
        Where-Object {$PsItem.Modulename -ne 'PsDesiredStateConfiguration'} |
        Sort-Object -Unique -Property Modulename  

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
                Copy-Item -Path "C:\Program Files\WindowsPowerShell\Modules\$Module" -ToSession $CurrentSession -Destination "C:\Program Files\WindowsPowerShell\Modules\$Module" -Force -Recurse
            }
        }
        catch
        {
            throw 'Unable to copy required module files to {0} - Error: {1}' -f $Psitem, $Node
        }
    }
}

static [void] CleanMofFolder($Nodes)
{
    $nodes | ForEach-Object { Remove-Item "$PSScriptRoot\mofs\$PsItem.mof" -Force -ErrorAction SilentlyContinue}
}

static [PsCustomObject] Initalize()
{
    try 
    {   
        [Vamp]::ImportPSYaml()
        $Spec = ConvertFrom-Yaml -Path $PSScriptRoot\vampspec.yml -As Hash
        [Vamp]::CleanMofFolder($Spec.Nodes.Name)
        return $Spec
    }
    catch
    {
        throw 'Unable to read Yaml - Error: {0}' -f $Psitem
    }

}

static [void] CreateMofTail([System.String]$Nodename)
{

foreach ($node in $nodename.Split(' ')){

@'
instance of OMI_ConfigurationDocument
                    {
 Version="2.0.0";
                        MinimumCompatibleVersion = "1.0.0";
                        CompatibleVersionAdditionalProperties= {"Omi_BaseResource:ConfigurationName"};
                    };
'@ | Out-File $PSScriptRoot\mofs\$node.mof -Force -Append

}

}

static [void] CreateMofHeader($Input, [System.String]$Nodename)
{

foreach ($node in $nodename.Split(' ')){

        foreach ($key in $Input.Keys)
        {
        $ref = Get-Random
            $Header = switch ($key) 
            {
                'service'     {"instance of MSFT_ServiceResource as `$MSFT_ServiceResource$($ref)ref"; break}
                'environment' {"instance of MSFT_EnvironmentResource as `$MSFT_EnvironmentResource$($ref)ref"; break }
                'directory'   {"instance of MSFT_FileDirectoryConfiguration as `$MSFT_FileDirectoryConfiguration$($ref)ref"; break }
                'file'        {"instance of MSFT_FileDirectoryConfiguration as `$MSFT_FileDirectoryConfiguration$($ref)ref"; break }
                'feature'     {"instance of MSFT_RoleResource as `$MSFT_RoleResource$($ref)ref"; break }
                'script'      {"instance of MSFT_ScriptResource as `$MSFT_ScriptResource$($ref)ref"; break }
                 $Psitem      {"instance of $PsItem as `$$($Psitem)$($ref)ref" ; break}
                 default      {throw 'No header found for {0}' -f $Psitem}
            }
            $Header | Out-File $PSScriptRoot\mofs\$node.mof -Force -Append
            Write-Verbose 'Finished Header'
        }
    }
    
}

static [void] CreateMofCore($Input, [System.String]$Nodename) 
{

foreach ($node in $nodename.Split(' ')) { 

    #Holy sheeet - need to change this once everything else works.
    $Reader = $Input.Values | Out-String -Stream
    $reader = $Reader -replace ': ','= ' `
                      -replace '= ','= "' `
                      -replace '$','";' `
                      -replace '^";','' `
                      -replace '(?<=DependsOn.*=\s+).*(?="\[)','{' `
                      -replace '(?<=DependsOn.*=\s+{"\[.*\].*").*(?=;).*(?=;)','}' `
                      -replace '"true"','true' `
                      -replace '"false"','false'

@"
{
$Reader
};
"@ | Out-File $PSScriptRoot\mofs\$node.mof -Force -Append

}

Write-Verbose 'Finished Core'
}

static Main()
{

$vampspec = [Vamp]::Initalize()

foreach ($i in $vampspec)
{
    foreach ($config in $i.configs.name) 
    {
    $CurrentConfig = ConvertFrom-Yaml -Path .\configs\$($config).yml
    
        for ($m = 0; $m -lt $CurrentConfig.count; $m++){

        [Vamp]::CreateMofHeader($CurrentConfig[$m], $i.nodes.name)

        [Vamp]::CreateMofCore($CurrentConfig[$m], $i.nodes.name)
        }

    
    }

   [Vamp]::CreateMofTail($i.nodes.name)    
}

}
}

Function Vamp {

<#
.Synopsis
   Vamp is a PowerShell tool that allows the creation of .MOF files for the DSC Local Configuration Manager to consume.
.DESCRIPTION
   Traditionally .MOF files can be generated by various tools. 
   This tool aims at allowing the simple creation of .MOF files for use with PowerShell Desired State Configuration from a YAML file.
.EXAMPLE
   If you choose to add the -prep switch parameter: The vamp the tool will simply assess modules required for the DSC configuration and attempt to download these from the PSGallery.
   This will not generate any mof files or apply any configuration

   vamp -prep

.EXAMPLE
   if you choose to add the -apply parameter: The vamp tool will run the preparation phase to download any required modules and then commence to create the associated .mof files for the desired configuration.
   After the mof files have been created the tool will apply DSC configuration to all .mof files within the "mofs" directory in the vamp root.

   vamp -apply
#>

[CmdletBinding()]
Param(
[AllowNull()]
[Switch]$prep,

[AllowNull()]
[Switch]$apply

)
    $ErrorActionPreference = 'Stop'

    if ($prep -eq $true)
    {
        $Nodes = [Vamp]::Initalize()
        [Vamp]::BootstrapNuget()

        $ToDownload = [Vamp]::FindModules()
        [Vamp]::DownloadModules($ToDownload)

        $targets = $Nodes.nodes.name | Sort-Object -Unique
        [Vamp]::CopyModules($targets, $ToDownload)
    }
    if ($apply -eq $true) 
    {
        [Vamp]::Main()
        Start-DscConfiguration $PSScriptRoot\mofs -Verbose -Wait -Force
    }

}
