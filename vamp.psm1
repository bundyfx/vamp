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

    if ($PSBoundParameters.Values -eq $null)
    {
        vamp -?
    }

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
          if ([Boolean](Test-WSMan $Node))
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
        if ([Boolean](Test-Wsman $Node))
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

              if ($Props.Password -eq $true -and $Props.Username -eq $true)
              {
                #Create psCredentail Object as required
                $Props.Password = [Helpers]::CreateCredentialObject($Props.Username, $Props.Password)
              }

              Invoke-Command -Session $Session -ScriptBlock {
              if (-not [Boolean](Invoke-DscResource -Method Test -Name $using:Name -ModuleName $using:Modulename -Property $using:props ))
                  {
                      $Output = Invoke-DscResource -Method Set -Name $using:Name -ModuleName $using:Modulename -Property $using:props -Verbose
                      Write-Output "Complete - Restart Required: $($Output.RestartRequired)"
                  }
                  else
                  {
                      Write-Output "$using:Name Resource for $using:Node is in Desired State"
                  }
              }
          }
          Remove-PSSession -Computername $Session.Computername
        }
      }
   }
}
