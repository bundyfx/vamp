using module ./private/vamp/helpers.psm1
using module ./private/PSYaml/PSYaml.psm1

function main(){

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

    foreach ($Node in $Nodes.Nodes.Name)
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
            if (-not [Boolean](Invoke-DscResource -Method Test -Name $using:Name -ModuleName $using:Modulename -Property $using:props -Verbose)) 
                {
                    Invoke-DscResource -Method Set -Name $using:Name -ModuleName $using:Modulename -Property $using:props -Verbose
                }
            }        
        }
        Remove-PSSession -Session $Session
    }
}