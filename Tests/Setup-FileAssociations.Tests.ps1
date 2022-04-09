BeforeAll {
    . .\Tests\CommonTestParameters.ps1

    . .\setup.ps1

    Set-Variable -Name "IniContent" -Value (Get-IniContent -FilePath ".\$TestGroup\settings\settings.ini" -IgnoreComments) -Scope Global
}

Describe "Setup-FileAssociations"{
    #    Context "Setup-FileAssociations"{
    #        BeforeAll{
    #            $DebugPreference = "continue"
    #            Setup-FileAssociations -Associations $IniContent["associations"]
    #            $DebugPreference = "silentlycontinue"
    #        }
    #        #ToDo Test for Setup-FileAssociations
    #    }
}