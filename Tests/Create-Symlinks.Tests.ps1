BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

Describe "Create-Symlinks"{
    Context "Create-Symlinks"{
        BeforeAll{
            $DebugPreference = "continue"
            Create-Symlinks -Group $TestGroup
            $DebugPreference = "silentlycontinue"
        }
        It "Steam config symlink"{
            Test-Symlink "C:\Program Files (x86)\Steam\config" | Should -Be $true
        }
        It "MSI Afterburner symlink"{
            Test-Symlink "C:\Program Files (x86)\MSI Afterburner\Profiles" | Should -Be $true
        }
        It "Ubisoft game launcher symlink"{
            Test-Symlink "C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\savegames" | Should -Be $true
        }
    }
}