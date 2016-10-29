using module .\private\Vamp\LCM.psm1
using module .\private\Vamp\Mof.psm1
#requires -RunAsAdministrator
#requires -version 5.0

Class Vamp {



}

Function Main(){

    #Import All private data
    (Get-Childitem .\private\PSYaml\PSYaml.psm1, .\private\Vamp).FullName | Import-Module -Verbose

    #Generate required meta.mof files
    [LCM]::Generate()

    #Generate required mof files
    [Mof]::Generate()

}
