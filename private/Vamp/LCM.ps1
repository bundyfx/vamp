Class LCM {
    
    static [void] Generate () 
    {
        #Importing the PSYaml module
        [Yaml]::Import()

        #Read Yaml for the desired role
        [Array]$Paths = "$PSScriptRoot\core\spec\", "$PSScriptRoot\core\config\"

        #Gather all spec files and read them
        [Array]$Files += $Paths.ForEach{ [System.IO.DirectoryInfo]::new($Psitem).EnumerateFiles() }
        $Nodes = $Files.Where{$Psitem -like '*.spec.yml'}.ForEach{ [Yaml]::Read($Psitem.Fullname) }

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
        }
    }
}