using module ./private/PSYaml/PSYaml.psm1
using module ./private/vamp/helpers.psm1
using module ./private/vamp/prep.psm1

InModuleScope helpers {
    Describe "Testing private modules" {
        Context "Reading Yaml with the Yaml Class (Config)" {
                Foreach ($Item in [System.IO.DirectoryInfo]::new("../../config").EnumerateFiles().Fullname)
                {
                    It "Should be able to read the example files in the config Folder: $Item" {
                    [Yaml]::Read($Item)
                    }
                }
            }
        Context "Reading Yaml with the Yaml Class (Spec)" {
            Foreach ($Item in [System.IO.DirectoryInfo]::new("../../spec").EnumerateFiles().Fullname)
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
    Describe "Should be able to find required modules in examples" {
        It "Should run FindModules Method" {
        $Modules = [VampPrep]::FindModules()
        $Modules | Should not be $null
        }
    }
}
