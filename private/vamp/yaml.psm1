#Simple methods to import the required module and read a Yaml file.
Class Yaml
{
    static [void] Import()
    {
        try
        {
            Import-Module $PsScriptRoot\private\PSYaml\PSYaml.psm1 -verbose:$false
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