using module .\private\Vamp\LCM.psm1
#requires -RunAsAdministrator
#requires -version 5.0

Function Main(){

    #Import All private data
    (Get-Childitem .\private\PSYaml\PSYaml.psm1, .\private\Vamp).FullName | Import-Module -Verbose

    #Generate and Apply required meta.mof files
    [LCM]::Generate()

    [MOF]::Generate()
    [MOF]::Apply()
      
}
