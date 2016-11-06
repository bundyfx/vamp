$Modules = Get-ChildItem $pwd.Path -Filter '*.psm1' -Recurse
$Rules = Get-ScriptAnalyzerRule

Describe "Linting all Modules in Repository" {
    foreach($Module in $Modules) {
        Context "Linting $($Module.BaseName)" {
            foreach ($Rule in $Rules) {
                It "Passess the Rule: $Rule" {
                    (Invoke-ScriptAnalyzer -Path $Module.FullName -IncludeRule $Rule.RuleName).Count | Should Be 0
                }
            }
        }
    }
}