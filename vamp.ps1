#requires -RunAsAdministrator
#requires -version 5.0

Function Vamp {
[CmdletBinding()]
Param([Switch]$prep)

$ErrorActionPreference = 'Stop'

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
        throw 'Unable to read Yaml - Error: {0}' -f $Psitem
    }
}

static [void] FindModules()
{
    try 
    {
        $requiredModules = Get-ChildItem $PSScriptRoot\configs\*.yml | 
        ForEach-Object {(ConvertFrom-Yaml -Path $Psitem.FullName).Values} | 
        Select Modulename,ModuleVersion | 
        Sort-Object -Unique -Property Modulename

        $currentModules = Get-Module -ListAvailable | 
        Select-Object @{Name='ModuleName';e={$Psitem.Name}},
        @{name='ModuleVersion';e={$Psitem.Version}}

        $searchScope = Compare-Object $requiredModules $currentModules -Property ModuleName,ModuleVersion -IncludeEqual | 
        Where-Object {$Psitem.Sideindicator -eq '=='}

        foreach ($module in $requiredmodules.Where{$psItem.Modulename -ne 'PsDesiredStateConfiguration'})
        {   
            Write-Verbose "Searching the PSGallery for $($module.modulename) - version $($module.moduleversion)"
            Install-Module -Name $module.Modulename -RequiredVersion $module.Moduleversion -Repository PsGallery -Verbose
        }
     
    }
    catch
    {
        throw 'Unable to download required module - Error: {0}' -f $Psitem
    }
}

static [System.String[]] Initalize()
{
    try 
    {
        
        $Spec = ConvertFrom-Yaml -Path $PSScriptRoot\vampspec.yml -As Hash
        $Spec.nodes.name | ForEach-Object { Remove-Item "$PSScriptRoot\mofs\$PsItem.mof" -Force -ErrorAction SilentlyContinue}
        return $Spec.nodes.name
    }
    catch
    {
        throw 'Unable to read Yaml - Error: {0}' -f $Psitem
    }

}

static [System.String[]] InitalizeConfigs()
{
Import-Module $PSScriptRoot\private\PSYaml\PSYaml.psm1
$Spec = ConvertFrom-Yaml -Path $PSScriptRoot\vampspec.yml -As Hash
return $Spec.configs.name
}

static [void] CreateMofTail([System.String[]]$Nodes)
{

foreach ($node in $nodes){
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

static [void] CreateMofHeader([Hashtable]$Input, [System.String[]]$Nodes)
{
foreach ($node in $nodes)
   {
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
        }
    }
}

static [void] CreateMofCore([Hashtable]$Input, [System.String[]]$Nodes) 
{
foreach ($node in $nodes){

    foreach ($yml in $Input) {

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
}
}

static Main()
{


Write-Verbose 'Commenced Main Method'
#Get main yml file
$yamlbind = [Vamp]::InitalizeConfigs()

#check for yaml at pwd
if ($yamlbind -eq $null){
    throw 'Unable to continue - Cannot find .yml file at {0}' -f $pwd.Path
}
$Base = (Get-ChildItem $PSScriptRoot).BaseName
if ($yamlbind.configs.name | ForEach-Object { $Psitem -in $Base })
{
    throw 'Unable to continue not all yaml files specified in vampspec are present in vamp root'
}

Write-Verbose "yml file $($yamlbind.Name) found locally"

$CoreResources = foreach ($config in $yamlbind){
#read main yml
Write-Verbose "reading yml file: $($config)"
[Vamp]::ReadYaml("$PSScriptRoot\configs\$($config).yml")
}


$nodes = [Vamp]::Initalize()
Write-Verbose 'Initializing'

foreach ($node in $nodes){
Write-Verbose "found $node in vampspec"

    foreach ($resource in $CoreResources){
    Write-Verbose 'Creating Header'
    [Vamp]::CreateMofHeader($Resource, $node)

    Write-Verbose 'Creating Core'
    [Vamp]::CreateMofCore($Resource, $node)

    }

    Write-Verbose 'Creating Tail'
    [Vamp]::CreateMofTail($node)

    Write-Verbose 'Ending'
    }
  }

}
if ($prep -eq $true){
[Vamp]::FindModules()
}
else 
{
#Calls main method of Vamp
[Vamp]::Main()
}
}
