Import-Module .\vamp.ps1 -Verbose
Import-Module .\PSYaml\PSYaml.psm1 -Verbose

Describe 'Yaml Conversion' -Tags 'Unit' {
  Context 'PSYaml Module' {
    It 'Should be able to convert to Yaml example.yml' {
       { ConvertFrom-Yaml -Path .\example.yml } | Should not throw
    }
    It 'Should be able to convert to Yaml vampspec.yml' {
       { ConvertFrom-Yaml -Path .\vampspec.yml } | Should not throw
    }
  }
}
