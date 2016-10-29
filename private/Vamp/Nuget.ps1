Class Nuget
{
  static [void] Install ()
  {
      try
      {
          Write-Verbose "Making sure the Nuget Package Provider is ready to use"
          Install-PackageProvider Nuget -ForceBootstrap -Force -Confirm:$false -Verbose:$false

          Write-Verbose "Setting PSGallery to be a trusted repository"
          Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -Verbose:$false
      }
      catch
      {
          throw 'Unable to Install Nuget package provider required for module installation - Error: {0}' -f $PSItem
      }
  }
}
