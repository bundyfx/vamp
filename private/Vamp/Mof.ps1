Class Mof
{
  static [void] Create([System.String]$TargetNode,
                       [System.String]$GeneratedBy,
                       [System.String]$GenerationDate,
                       [System.String]$GenerationHost,
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

    instance of {4} as {5}
    {{
    {6}
    ConfigurationName = "{5}";
    }};
    instance of OMI_ConfigurationDocument


                        {{
     Version="2.0.0";


                            MinimumCompatibleVersion = "1.0.0";


                            CompatibleVersionAdditionalProperties= {{"Omi_BaseResource:ConfigurationName"}};


                            Author="{1}";


                            GenerationDate="{2}";


                            GenerationHost="{3}";


                            Name="{6}";


                        }};
'@ -f $TargetNode, $GeneratedBy, $GenerationDate, $GenerationHost, $GenerationHost, $ConfigurationName, $Body

$Mof | Out-File C:\temp\mof.mof
  }

}
