using module ./private/PSYaml/PSYaml.psm1
using module ./private/vamp/conversion.psm1
using module ./private/vamp/yaml.psm1
using module ./private/vamp/prep.psm1

InModuleScope conversion {
    Describe "Testing private modules" {
        Context "Reading Yaml with the Yaml Class (Config)" {
                Foreach ($Item in [System.IO.DirectoryInfo]::new("$($pwd.path)\config").EnumerateFiles().Fullname)
                {
                    It "Should be able to read the example files in the config Folder: $Item" {
                    [Yaml]::Read($Item)
                    }
                }
            }
        Context "Reading Yaml with the Yaml Class (Spec)" {
                It "Should throw if nothing passed in" {
                {[Yaml]::Read()} | should throw
                }
            Foreach ($Item in [System.IO.DirectoryInfo]::new("$($pwd.path)\spec").EnumerateFiles().Fullname)
            {
                It "Should be able to read the example files in the spec Folder: $Item" {
                [Yaml]::Read($Item)
                }
                It "Should only have nodes and configs in the spec file" {
                $specfile = [Yaml]::Read($Item)
                $specfile.keys.ForEach{$Psitem | Should match 'configs|nodes'}
                }
            }
        }
    }
}


InModuleScope prep {
    Describe "Method Testing" {
        It "FindModules() Should throw since nothing passed in" {
        {[VampPrep]::FindModules()} | should throw

        }
        It "DownloadModules() Should throw since nothing passed in" {
        {[VampPrep]::DownloadModules()} | should throw
        
        }
        It "Compare() Should throw since nothing passed in" {
        {[VampPrep]::Compare()} | should throw
        
        }
        It "CopyModules() Should throw since nothing passed in" {
        {[VampPrep]::CopyModules()} | should throw
        
        }
    }
}
