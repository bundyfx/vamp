$Modules = Get-ChildItem $pwd.Path -Filter '*.psm1' -Recurse

Describe "Linting all Modules in Repository" {
    foreach($Module in $Modules) {
        Context "Linting $Module" {
              It "Passes ScriptAnalyzer" {
                  (Invoke-ScriptAnalyzer -Path $Module.FullName).count | Should Be 0
              }
        }
    }
}
