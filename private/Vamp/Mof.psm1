Class Mof
{
  static [void] Generate([System.String]$TargetNode,
                         [System.String]$Resource,
                         [System.String]$ConfigurationName,
                         [System.String]$Body
                        )
  {
  $Mof = @'
  /*
  @TargetNode={0}
  @GeneratedBy={1}
  @GenerationDate={2}
  @GenerationHost={3}
  */
  instance of {7} as {5}
  {{
  {6}
  ConfigurationName = "{4}";
  }};
  instance of OMI_ConfigurationDocument
  {{
  Version="2.0.0";
  MinimumCompatibleVersion = "1.0.0";
  CompatibleVersionAdditionalProperties= {{"Omi_BaseResource:ConfigurationName"}};
  Name="{4}";
  }};
'@ -f $TargetNode, $Env:USERNAME, [String](Get-Date -Format MM/dd/yyyy), $Env:COMPUTERNAME, $ConfigurationName, ("$" + $Resource + (Get-Random) + 'ref'), $Body, $Resource

$Mof | Out-File $PSScriptRoot\output -Force
  }

}
