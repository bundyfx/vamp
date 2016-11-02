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
     [Switch]$testall,

     [AllowNull()]
     [Switch]$prep,

     [AllowNull()]
     [Switch]$generate,

     [AllowNull()]
     [Switch]$apply
     )

    $ErrorActionPreference = 'Stop'
    $Nodes = [VampPrep]::Nodes()

    #Import All private data
    (Get-Childitem .\private\PSYaml\PSYaml.psm1, .\private\Vamp).FullName | Import-Module -Verbose
    if ($testall -eq $true)
    {
        $Nodes = [VampPrep]::Nodes()
        $Nodes | ForEach-Object {
        if ([Bool](Test-WSMan $Psitem -ea 4))
        {
          Write-Host "Node $PSItem is online" -foreground 'Green'
        }
        else
        {
          Write-Host "Node $PSItem is offline" -foreground 'Red'
        }
    }
    }
    if ($prep -eq $true)
    {      
        [VampPrep]::BootstrapNuget()

        $ToDownload = [VampPrep]::FindModules()
        [VampPrep]::DownloadModules($ToDownload)

        [VampPrep]::CopyModules($nodes, $ToDownload)
        [LCM]::Generate()
        Write-Output 'Prep complete'
    }

    if ($generate -eq $true)
    {
        [MOF]::Compile()
    }
    if ($apply -eq $true)
    {
        [MOF]::Apply($Nodes)
    }
}
