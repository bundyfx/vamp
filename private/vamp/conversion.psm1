<#
A Class of methods that are used for modularity of the project.
These are housed under a single 'Helpers' Class until the time comes for futher seperation and extensibility
#>
Class Conversion
{
    static [Hashtable] ConvertToHash([psCustomObject]$InputObject)
    {
        #Define our intended error action - Stop if any errors are encounted
        $ErrorActionPreference = 'Stop'

        #Iterate through each item within the input Custom Object
        foreach ($PsObject in $InputObject) {
            #try the following; if any errors are encounted stop execution and execute the catch block
            try
            {
                #Ordered Hashtable removes the need for Depends on - simply execute the resources in order as layed out in the yml files
                $output = [Ordered]@{}

                #Collecting the NoteProperty members from the current object in the collection
                $Properties = $PsObject | Get-Member -MemberType NoteProperty

                #Foreach of the NoteProperty's within the Propeties Object
                foreach ($Property in $Properties)
                {
                    # If the current object matches the regular expression that defines an integer
                    if ($psobject.($Property.Name) -match '^\d+$') {

                        #Create an entry in the hashtable with the same name and Value however casted as a Uint32
                        $output.($Property.name) = $Psobject.($Property.name) -as [Uint32[]]
                    }
                    # If the current object matches the regular expression that defines an boolean
                    elseif ($psobject.($Property.Name) -match 'true|false')
                    {
                        #Create an entry in the hashtable with the same name and Value however casted as a boolean
                        $output.($Property.name) = $Psobject.($Property.name) -as [Boolean]
                    }
                    # If the current object matches the regular expression that defines anything use default (string) cast
                    else
                    {
                        #Create an entry in the hashtable with the same name and Value
                        $output.($Property.name) = $Psobject.($Property.name)
                    }
                }
            }
            #If any errors occured during the above try block stop and throw an error
            catch [Exception]
            {
                #throws a terminating error with the error message
                throw 'Error: {0}' -f $Psitem
            }

         # Returns the output object back to the caller
         return $output
      }
      # Will update this continue statement in the very near future - all class paths don't return valid objects unless its specified.
      continue
    }

    static [psCredential] CreateCredentialObject ([System.String]$Username, [System.String]$Password)
    {
        $creds = [pscredential]::new($Username,($Password | ConvertTo-SecureString -AsPlainText -Force ))
        return $creds
    }

    static [void] PreChecks ()
    {
      #Build smart pre-checks here for ensuring spec files are correct prior to starting
    }

}
