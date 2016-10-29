Class Yaml {

    static [void] Import()
    {
        try
        {
            Import-Module .\private\PSYaml\PSYaml.psm1
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
        catch
        {
            throw 'Unable to read Yaml - Error: {0} ' -f $Psitem
        }
    }
}
