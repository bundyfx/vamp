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
Describe 'vamp core' -Tags 'Acceptance' {
  Context 'Calling vamp' {
    It 'Should call vamp correctly and create mofs' {
       { vamp } | Should not throw
    }
    It 'Should generate mofs for nodes in vampspec.yml' {
       $Output = (Get-ChildItem -Filter *.mof).Basename
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
    Get-ChildItem -Filter *.mof | Where-Object {$Psitem.Name -ne 'localhost.mof'} | Remove-Item -Force
    { Start-DscConfiguration -Path . -Verbose -Wait -Force } | Should not throw
    }

  }
}

