Class Yaml 
{

    static [void] Import()
    {
        try
        {
            Import-Module .\private\PSYaml\PSYaml.psm1
        }
        catch
        {
            throw 'Unable to Import PSYaml Module - Error: {0}' -f $Psitem
        }
    }

    static [PsCustomObject] Read([System.String]$Path)
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
}

Class MOF
{
  static [void] Apply()
  {
      try
      {
         Publish-DscConfiguration -Path .\output -Verbose
         Start-DscConfiguration -UseExisting -Wait -Force
      }
      catch
      {
         throw 'Error: {0}' -f $Psitem
      } 
  
  }

  static [void] ParseConfig([System.String]$TargetNode,
                            [System.String]$Resource,
                            [System.String]$ConfigurationName,
                            [System.String]$Body
                           )
  {
  $Mof = @'
  /*
  @TargetNode={0}
  @GeneratedBy={1}
  @GenerationDate={2}
  @GenerationHost={3}
  */
  instance of {7} as {5}
  {{
  {6}";
  ConfigurationName = "{4}";
  }};
  instance of OMI_ConfigurationDocument
  {{
  Version="2.0.0";
  MinimumCompatibleVersion = "1.0.0";
  CompatibleVersionAdditionalProperties= {{"Omi_BaseResource:ConfigurationName"}};
  Name="{4}";
  }};
'@ -f $TargetNode, $Env:USERNAME, [String](Get-Date -Format MM/dd/yyyy), $Env:COMPUTERNAME, $ConfigurationName, ("$" + $Resource + (Get-Random) + 'ref'), $Body, $Resource

$Mof | Out-File "$($PWD.Path)\output\$TargetNode.mof" -Force
  }


  static [Void] Generate()
  {
        #Importing the PSYaml module 
        [Yaml]::Import()

        #Read Specs and Config
        $Resources = [YamlConversion]::Read("$($pwd.Path)\core\config\")
        $Nodes = [YamlConversion]::Read("$($pwd.Path)\core\spec\")

        foreach ($Node in $Nodes.nodes.name)
        {
            foreach ($Resource in $Resources)
            {
                [String]$Key = $Resource.keys
                $ResourceString = ($Resource.$Key | ForEach-Object {$PSItem -join ''  -replace '=','="' -replace '^@{','' -replace '}$' -replace ';','";'})
                [Mof]::ParseConfig($node, 
                                   $Resource.keys, 
                                   ($nodes.where{$Psitem.nodes.name -eq $Node}.configs.name),
                                   $ResourceString
                                  )
            }
        }
        
  }

}

Class YamlConversion 
{

    static [PsCustomObject] Read ([System.String[]]$Path) 
    {
        #Gather all spec files and read them
        [Array]$Files += $Path.ForEach{ [System.IO.DirectoryInfo]::new($Psitem).EnumerateFiles() }
        $Nodes = $Files.ForEach{ [Yaml]::Read($Psitem.Fullname) }

        return $nodes
    }
}

Class LCM 
{
    static [void] Apply([System.String]$Node)
    {
        try 
        {
            Set-DscLocalConfigurationManager -Path .\output -Verbose -ComputerName $Node
        }
        catch [Exception]
        {
            throw 'Error: {0}' -f $Psitem
        }
    
    }

    static [void] Generate () 
    {      
        #Importing the PSYaml module 
        [Yaml]::Import()

        #Read Specs and Config
        $Nodes = [YamlConversion]::Read("$($pwd.Path)\core\spec\")

        #Generate meta config for all required nodes
        foreach ($Node in $Nodes.nodes.name)
        {
            #The configs for the node in the loop
            $Configs = $nodes.Where{$Psitem.nodes.name -eq $Node}.configs.name

            [DSCLocalConfigurationManager()]
            configuration LCM
            {
                Node $node
                {
                    foreach ($Config in $Configs)
                    {
                        PartialConfiguration $Config
                        {
                            RefreshMode = 'Push'
                            Description = 'Vamp Partial Config: {0}' -f $Config
                        }            
                    }
                }
            }
           LCM -OutputPath .\output
           Write-Verbose "Meta.mof created for $node"
           [LCM]::Apply($node)
           
        }

    }
}