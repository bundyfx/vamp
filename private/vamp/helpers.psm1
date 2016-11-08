Class Helpers
{
  static [Hashtable] ConvertToHash([psCustomObject]$InputObject)
  {
    foreach ($PsObject in $InputObject) {
        $output = [Ordered]@{};
        $PsObject | Get-Member -MemberType *Property | ForEach-Object {
            $output.($Psitem.name) = $PsObject.($Psitem.name);
        }
        return $output;
    }
   throw 'No Hashtable to return'
  }

  static [psCredential] CreateCredentialObject ([System.String]$Username, [System.String]$Password)
  {
    $creds = [pscredential]::new('{0}' -f $Username,(ConvertTo-SecureString -String $Password -AsPlainText -Force))
    return $creds
  }


}


Class Yaml
{

    static [void] Import()
    {
        try
        {
            Import-Module .\private\PSYaml\PSYaml.psm1 | Out-Null
        }
        catch
        {
            throw 'Unable to Import PSYaml Module - Error: {0}' -f $Psitem
        }
    }

    static [PsCustomObject] Read([System.String]$Path)
    {
        try
        {

            $Reader = ConvertFrom-Yaml -Path $Path -As Hash
            return $Reader
        }
        catch [System.Management.Automation.RuntimeException]
        {
            throw 'Unable to read Yaml - Error: {0} ' -f $Psitem
        }
    }
}
