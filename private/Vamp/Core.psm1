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
  static [void] Apply($Nodes)
  {
      try
      {
         Start-DscConfiguration -CimSession $Nodes -UseExisting -Wait -Force
      }
      catch
      {
         throw 'Error: {0}' -f $Psitem
      }

  }
  static [void] GenerateHeader([System.String]$TargetNode)
  {
  $MofHead = @'
  /*
  @GeneratedBy={0}
  @GenerationDate={1}
  @GenerationHost={2}
  */
'@ -f $Env:USERNAME, [String](Get-Date -Format MM/dd/yyyy), $Env:COMPUTERNAME | Out-File .\output\$Targetnode.mof -Force
   }
  static [void] GenerateBody([System.String]$TargetNode,
                             [System.String]$Resource,
                             [System.String]$ConfigurationName,
                             [System.String]$Body)
  {
  $MofBody = @'
  instance of {0} as {1}
  {{
  {2};
  ConfigurationName = "{3}";
  }};
'@ -f $Resource, ("$" + $Resource + (Get-Random) + 'ref'), $Body, $ConfigurationName | Out-File .\output\$Targetnode.mof -Force -Append
   }
  static [void] GenerateTail([System.String]$TargetNode, [System.String]$ConfigurationName)
  {
  $MofTail = @'
  instance of OMI_ConfigurationDocument
  {{
  Version="2.0.0";
  MinimumCompatibleVersion = "1.0.0";
  CompatibleVersionAdditionalProperties= {{"Omi_BaseResource:ConfigurationName"}};
  Name="{0}";
  }};
'@ -f $ConfigurationName | Out-File .\output\$Targetnode.mof -Force -Append

  }
  static [Void] Compile()
  {
        #Importing the PSYaml module
        [Yaml]::Import()

        $SpecFiles = [System.IO.DirectoryInfo]::new("$($pwd.Path)\core\spec\").EnumerateFiles()
        $ConfigFiles = [System.IO.DirectoryInfo]::new("$($pwd.Path)\core\config\").EnumerateFiles()

        [Array]$Nodes += foreach ($File in $SpecFiles)
        {
            [Yaml]::Read($File.Fullname)
        }
        foreach ($File in $ConfigFiles)
        {
            $Configs = [Yaml]::Read($File.Fullname)
            foreach($Node in $Nodes.nodes.name)
            {
                [MOF]::GenerateHeader($Node)
                foreach ($Item in $Configs)
                {
                    [String]$Key = $Item.keys
                    $Body = ($Item.$Key | ForEach-Object {$PSItem -join '' } ) -replace ';','";' `
                                                                  -replace '=','="' `
                                                                  -replace '^@{','' `
                                                                  -replace '}$','"' `
                                                                  -replace '((?<=DependsOn=).*?(?=;))' , '{$1}'

                    [MOF]::GenerateBody($Node, $Key, $File.BaseName, $Body)
                }

                [MOF]::GenerateTail($Node, $File.BaseName)

                Publish-DscConfiguration .\output -ComputerName $Node -Verbose
                Remove-Item (Join-Path .\output\ -ChildPath "$Node`.mof") -Force
            }
        }
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

        $SpecFiles = [System.IO.DirectoryInfo]::new("$($pwd.Path)\core\spec\").EnumerateFiles()

        [Array]$Nodes += foreach ($File in $SpecFiles)
        {
            [Yaml]::Read($File.Fullname)
        }

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
