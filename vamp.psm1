#requires -RunAsAdministrator
#requires -version 5.0
using module ./private/vamp/helpers.psm1
using module ./private/vamp/prep.psm1
using module ./private/PSYaml/PSYaml.psm1

function vamp(){
  [CmdletBinding()]
  Param(
     [AllowNull()]
     [Switch]$testall,

     [AllowNull()]
     [Switch]$prep,

     [AllowNull()]
     [Switch]$apply
     )
<#

Built in Resources:

Archive
Environment
File
Group
Log
Package
Registry
Script
Service
User
WindowsFeature
WindowsProcess
#>

    $SpecFiles = [System.IO.DirectoryInfo]::new("$($pwd.Path)\spec\").EnumerateFiles()
    $ConfigFiles = [System.IO.DirectoryInfo]::new("$($pwd.Path)\config\").EnumerateFiles()

    [Array]$Nodes += foreach ($File in $SpecFiles)
    {
        [Yaml]::Read($File.Fullname)
    }

    #if the -testall param has been passed
    if ($testall -eq $true)
    {
        #Ensure all nodes are gathered, Test-WSMAN on each remote node.
        foreach ($Node in $Nodes.Nodes.name)
        {
            if ([Bool](Test-WSMan $Node -ErrorAction SilentlyContinue))
            {
              Write-Output "Node $Node is online"
            }
            else
            {
              Write-Output "Node $Node is OFFLINE"
            }
        }
    }

    if ($prep -eq $true)
    {
        Write-Output "Starting Prep..."
        Write-Output "Ensuring Nuget is accessable"
        [VampPrep]::BootstrapNuget()

        Write-Output "Finding Required Modules"
        $ToDownload = [VampPrep]::FindModules()
        Write-Verbose "The required modules for these configuration are: $($ToDownload.Modulename)"

        Write-Output "Downloading Required Modules"
        [VampPrep]::DownloadModules($ToDownload)

        foreach($Node in $Nodes.nodes.name)
        {
          if (Test-Connection $Node -Quiet -Count 1)
          {
            Write-Output "Copying Modules to $Node"
            [VampPrep]::CopyModules($Node, $ToDownload)
          }
        }
        Write-Output "Prep Complete"
    }

    if ($apply -eq $true)
    {
      foreach ($Node in $Nodes.Nodes.Name)
      {
        if (Test-Connection $Node -Quiet -Count 1)
        {
          [Array]$Configs = foreach ($File in $ConfigFiles.where{$Psitem.basename -in ($Nodes.where{$Psitem.nodes.name -eq $Node}.configs.name)})
          {
              [Yaml]::Read($File.Fullname)
          }

          $Session = New-PSSession -ComputerName $Node
          foreach ($Config in $Configs)
          {
              [String]$Name = $Config.Keys
              $Props = [Helpers]::ConvertToHash($Config.Values)
              $Modulename = $Config.values.ModuleName
              $Props.Remove('ModuleName')

              Invoke-Command -Session $Session -ScriptBlock {
              if (-not [Boolean]($Test = Invoke-DscResource -Method Test -Name $using:Name -ModuleName $using:Modulename -Property $using:props ))
                  {
                      $Output = Invoke-DscResource -Method Set -Name $using:Name -ModuleName $using:Modulename -Property $using:props -Verbose
                      Write-Output "Restart Required: $($Output.RestartRequired)"
                  }
                  else
                  {
                      Write-Output "$using:config in desired state: $($Test.InDesiredState)"
                  }
              }
          }
          Remove-PSSession -Computername $Session.Computername
        }
      }
   }
}
