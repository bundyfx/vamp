using module .\private\Vamp\core.psm1
using module .\private\Vamp\prep.psm1
#requires -RunAsAdministrator
#requires -version 5.0

Function vamp(){
<#
#>

[CmdletBinding()]
Param(
     [AllowNull()]
     [Switch]$prep,

     [AllowNull()]
     [Switch]$apply
     )

    $ErrorActionPreference = 'Stop'

    #Import All private data
    (Get-Childitem .\private\PSYaml\PSYaml.psm1, .\private\Vamp).FullName | Import-Module -Verbose
    if ($prep -eq $true)
    {
        $Nodes = [VampPrep]::Nodes()
        Write-Output $Nodes
        [VampPrep]::BootstrapNuget()

        $ToDownload = [VampPrep]::FindModules()
        [VampPrep]::DownloadModules($ToDownload)

        [VampPrep]::CopyModules($nodes, $ToDownload)
        [LCM]::Generate()
        Write-Output 'Prep complete'
    }

    if ($apply -eq $true)
    {
        [LCM]::Generate()
        [MOF]::Compile()
        [MOF]::Apply()
    }
}
