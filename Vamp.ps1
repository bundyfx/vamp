#requires -RunAsAdministrator
#requires -version 5.0

Function Vamp {
[CmdletBinding()]
Param()

$ErrorActionPreference = 'Stop'

Class Vamp {

static [PsCustomObject] ReadYaml([System.String]$Path)
{
    try 
    {
        Import-Module $PSScriptRoot\PSYaml\PSYaml.psm1 -Verbose
        $Reader = ConvertFrom-Yaml -Path $Path -As Hash
        return $Reader
    }
    catch
    {
        throw 'Unable to read Yaml - Error: {0}' -f $Psitem
    }
}

static [System.String[]] Initalize()
{
    try 
    {
        Import-Module $PSScriptRoot\PSYaml\PSYaml.psm1
        $Spec = ConvertFrom-Yaml -Path $PSScriptRoot\vampspec.yml -As Hash
        $Spec.values.name | ForEach-Object { Remove-Item "$PSScriptRoot\$PsItem.mof" -Force -ErrorAction SilentlyContinue}
        return $Spec.values.name
    }
    catch
    {
        throw 'Unable to read Yaml - Error: {0}' -f $Psitem
    }

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
'@ | Out-File $PSScriptRoot\$node.mof -Force -Append
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
                'service'   {"instance of MSFT_ServiceResource as `$MSFT_ServiceResource$($ref)ref"; break}
                'directory' {"instance of MSFT_FileDirectoryConfiguration as `$MSFT_FileDirectoryConfiguration$($ref)ref"; break }
                 $Psitem    {"instance of $PsItem as `$$($Psitem)$($ref)ref" ; break}
                 default    {throw 'No header found for {0}' -f $Psitem}
            }
            $Header | Out-File $PSScriptRoot\$node.mof -Force -Append
        }
    }
}

static [void] CreateMofCore([Hashtable]$Input, [System.String[]]$Nodes) 
{
foreach ($node in $nodes){
$Reader = $Input.Values | Out-String
$reader = $Reader -replace ': ','= ' -replace '= ','= "' -replace ';','";' -replace '(?<=DependsOn.*=\s+).*(?="\[)','{' -replace '(?<=DependsOn.*=\s+{"\[.*\].*").*(?=;).*(?=;)','}'

@"
{
$Reader
};
"@ | Out-File $PSScriptRoot\$node.mof -Force -Append
}
}

static Main()
{


Write-Verbose 'Commenced Main Method'
#Get main yml file
$yamlbind = (Get-ChildItem -Filter *.yml).Where{$PsItem.name -ne 'vampspec.yml'}

#check for yaml at pwd
if ($yamlbind -eq $null){
    throw 'Unable to continue - Cannot find .yml file at {0}' -f $pwd
}
Write-Verbose "yml file $($yamlbind.Name) found locally"

#read main yml
Write-Verbose "reading yml file: $($yamlbind.Name)"
$CoreResources = [Vamp]::ReadYaml("$PSScriptRoot\$($yamlbind.Name)")

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
#Calls main method of Vamp
[Vamp]::Main()

}