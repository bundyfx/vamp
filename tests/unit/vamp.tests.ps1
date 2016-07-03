Import-Module .\vamp.ps1 -Verbose
Import-Module .\private\PSYaml\PSYaml.psm1 -Verbose

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
Describe 'vamp core' -Tags 'Acceptance' {
  Context 'Calling vamp' {
    It 'Should call vamp correctly and create mofs' {
       { vamp } | Should not throw
    }
    It 'Should generate mofs for nodes in vampspec.yml' {
       $Output = (Get-ChildItem .\mofs -Filter *.mof).Basename
       $Nodes = ConvertFrom-Yaml -Path .\vampspec.yml
      
       $nodes.Values.name | ForEach-Object {$Psitem -in $Output} | Should be $true
    }
    It 'Should be able to generate new yml for localhost' {
@'
-  nodes:
    name : 
     - localhost

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
  Context "Advanced custom module vamp acceptance testing" {
      it "Should be able to create mofs with custom modules" {
          #move files for vamp to pick up new yml
        
          Move-Item .\example.yml -Destination .\tests -Force
          Copy-Item .\tests\acceptance\customModules.yml -Destination .\

          { vamp } | Should not throw
      }
      It "Should be able to apply DSC to localhost from vamp output - Custom Module xWebAdministration" {
          { Start-DscConfiguration -Path .\mofs -Verbose -Wait -Force } | Should not throw
          Remove-Item .\customModules.yml -Force
          Move-Item .\ -Destination .\tests\example.yml -Force
          Remove-Item .\mofs\localhost.mof -force
      }
  
  }
}

