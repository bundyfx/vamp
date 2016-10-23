Import-Module .\vamp.ps1 -Verbose
Import-Module .\private\PSYaml\PSYaml.psm1 -Verbose

Describe 'Yaml Conversion' -Tags 'Unit' {
  Context 'PSYaml Module' {
    It 'Should be able to convert to Yaml | vampspec.yml (Example file)' {
       { [Vamp]::ReadYaml("$pwd\vampspec.yml") } | Should not throw
    }
    It 'Should be able to convert to Yaml | BasicExample.yml (Example file)' {
       { [Vamp]::ReadYaml("$pwd\examples\BasicExample.yml")  } | Should not throw
    }
    It 'Should be able to convert to Yaml | AnotherExample.yml (Example file)' {
       { [Vamp]::ReadYaml("$pwd\examples\AnotherExample.yml")  } | Should not throw
    }
    It 'Should be able to convert to Yaml | YetAnotherExample.yml (Example file)' {
       { [Vamp]::ReadYaml("$pwd\examples\YetAnotherExample.yml") } | Should not throw
    }
    }
}
Describe 'static methods tests' -Tags 'Acceptance' {
        It 'ImportPSYaml method Should import the PSYaml module' {
        Remove-Module PSYaML -Verbose

        [Vamp]::ImportPSYaml()

        Get-Module PSYaml | Should be $true
    }
        It 'BootstrapNuget method Should download the Nuget Package Provider and Set tPSGallery to Trusted' {

        [Vamp]::BootstrapNuget()

        Get-PackageProvider NuGet | Should be $true
        (Get-PSRepository -Name PsGallery).InstallationPolicy | Should be 'Trusted'
    }
        It 'FindModules method Should search for and find any specified modules for the configuration' {

        $RequiredModules = [Vamp]::FindModules()

        $RequiredModules | Should beofType PsCustomObject
        $requiredModules | Should Not BeNullOrEmpty
    }
        It 'DownloadModules method should download any of the modules found by the FindModules method' {

        $RequiredModules = [Vamp]::FindModules() #before download
        [Vamp]::DownloadModules($RequiredModules) #download

        $Installed = Get-Childitem 'C:\Program Files\WindowsPowerShell\Modules' | Select -ExpandProperty Name
        $RequiredModules.Modulename | ForEach-Object {$Psitem -in $Installed} | Should be $true

    }
}

Describe 'vamp core' -Tags 'Acceptance' {
  Context 'Calling vamp help' {
        It 'Should not throw even though no parmeters passed in' {
           { vamp } | Should not throw
        }
        It 'Should bring up the help for vamp when using -?' {
           { vamp -? } | Should not throw
        }

    }
    Context 'Calling vamp -prep' {
        It 'Should be able to generate new yml for localhost with multiple configs' {
@'
-  nodes:
    name :
     - localhost

   configs:
    name :
     - BasicExample
     - AnotherExample
     - MoreExamples
     - YetAnotherExample

'@ | Out-file .\vampspec.yml -Force

{ ConvertFrom-Yaml -Path .\vampspec.yml } | Should not throw
  }
        It 'Should run vamp -prep correctly and download required modules' {
           { vamp -prep -verbose } | Should not throw
        }
    }
    Context 'vamp -prep output' { #needs to be rewritten to check version etc
    $Current = Get-Module -ListAvailable

        It 'Should locate required modules downloaded by -prep | xWebAdministration' {
           $Current.Where{$Psitem.name -eq 'xWebAdministration'} | Should be $true
           Test-Path 'C:\Program Files\WindowsPowerShell\Modules\xWebAdministration' | Should be $true
           }
        It 'Should locate required modules downloaded by -prep | xPowerShellExecutionPolicy' {
           $Current.Where{$Psitem.name -eq 'xPowerShellExecutionPolicy'} | Should be $true
           Test-Path 'C:\Program Files\WindowsPowerShell\Modules\xPowerShellExecutionPolicy' | Should be $true
           }
        It 'Should locate required modules downloaded by -prep | xDSCFireWall' {
           $Current.Where{$Psitem.name -eq 'xDSCFirewall'} | Should be $true
           Test-Path 'C:\Program Files\WindowsPowerShell\Modules\xDSCFirewall' | Should be $true
           }
        }
    }
Describe 'vamp -generate output' {
    Context 'vamp -generate should call the Main Method to create required .mof files' { #break this down into many more detailed tests
        It 'Should call vamp -generate correctly and not throw' {
        { vamp -generate -verbose } | Should not throw
        }
        It 'Should call vamp -generate correctly and generate .mof files' {

        $spec = [Vamp]::ReadYaml("$pwd\vampspec.yml")
        $mofs = (Get-Childitem $pwd\configs\*.mof).Basename
        foreach ($item in $mofs)
        {
            $item -in $spec.nodes.name | Should be $true
        }

        }
    }
}
Describe 'vamp -apply output' {
    Context 'vamp -apply should apply the generated mof files' { #break this down into many more detailed tests
        It 'Should apply configurations correctly' {

        { vamp -apply -Verbose } | Should not throw

        }
    }
}
