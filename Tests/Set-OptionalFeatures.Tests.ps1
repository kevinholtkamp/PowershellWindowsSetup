BeforeAll {
    . .\Tests\CommonTestParameters.ps1

    . .\setup.ps1

    Set-Variable -Name "IniContent" -Value (Get-IniContent -FilePath ".\$TestGroup\settings\settings.ini" -IgnoreComments) -Scope Global
}

Describe "Set-OptionalFeatures"{
    Context "Set-OptionalFeatures"{
        BeforeAll{
            $DebugPreference = "continue"
            Set-OptionalFeatures -Features $IniContent["optionalfeatures"]
            $DebugPreference = "silentlycontinue"
        }
        It "Optional feature DirectPlay"{
            Get-WindowsOptionalFeature -FeatureName "DirectPlay" -Online | Where-Object {$_.state -eq "Enabled"} | Should -Be $true
        }
        It "Optional feature TelnetClient"{
            Get-WindowsOptionalFeature -FeatureName "TelnetClient" -Online | Where-Object {$_.state -eq "Enabled"} | Should -Be $true
        }
    }
}