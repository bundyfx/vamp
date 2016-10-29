using module C:\git\vamp\private\Vamp\LCM.psm1
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

}
