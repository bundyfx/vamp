Import-Module .\vamp.ps1 -Verbose
Import-Module .\private\PSYaml\PSYaml.psm1 -Verbose

Describe 'Yaml Conversion' -Tags 'Unit' {
  Context 'PSYaml Module' {
    It 'Should be able to convert to Yaml example.yml (Example file)' {
       { ConvertFrom-Yaml -Path .\examples\example.yml } | Should not throw
    }
    It 'Should be able to convert to Yaml vampspec.yml (Example file)' {
       { ConvertFrom-Yaml -Path .\vampspec.yml } | Should not throw
    }
    It 'Should be able to convert to Yaml customModules.yml (Example file)' {
       { ConvertFrom-Yaml -Path .\examples\customModules.yml } | Should not throw
    }
    It 'Should be able to convert to Yaml customModulesAdvanced.yml (Example file)' {
       { ConvertFrom-Yaml -Path .\examples\customModulesAdvanced.yml } | Should not throw
    }
  }
}
Describe 'vamp core' -Tags 'Acceptance' {
  Context 'Calling vamp' {
    It 'Should throw since no .yml files are in root' {
       { vamp } | Should throw
    }
    It 'Should run vamp correctly and generate mofs for nodes in vampspec' {
       Copy-Item .\configs\*.yml -Destination .\ -Force
       { vamp } | Should not throw
    }
    It 'Should generate mofs for nodes in vampspec.yml' {
       $Output = (Get-ChildItem .\mofs -Filter *.mof).Basename
       $Nodes = ConvertFrom-Yaml -Path .\vampspec.yml
      
       $nodes.nodes.name | ForEach-Object {$Psitem -in $Output} | Should be $true
    }
    It 'Should be able to generate new yml for localhost' {
@'
-  nodes:
    name : 
     - localhost

-  configs:
    name :
     - example

'@ | Out-file .\vampspec.yml -Force

{ ConvertFrom-Yaml -Path .\vampspec.yml } | Should not throw 

    }
    It "should be able to call vamp with newly created yml" {
    { vamp } | should not throw
    }
    It "should be able to apply DSC to localhost from vamp output" {
        Get-ChildItem .\mofs -Filter *.mof | Where-Object {$Psitem.Name -ne 'localhost.mof'} | Remove-Item -Force
        { Start-DscConfiguration -Path .\mofs -Verbose -Wait -Force } | Should not throw
        Remove-Item .\mofs\localhost.mof -force
    }

  }

}

