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
            Test-Symlink "TestDrive:\Program Files (x86)\Steam\config" | Should -Be $true
            "TestDrive:\Links\Settings\Steam\config" | Should -Exist
        }
        It "MSI Afterburner symlink"{
            Test-Symlink "TestDrive:\Program Files (x86)\MSI Afterburner\Profiles" | Should -Be $true
            "TestDrive:\Links\Settings\MSIAfterburner" | Should -Exist
        }
        It "Ubisoft game launcher symlink"{
            Test-Symlink "TestDrive:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\savegames" | Should -Be $true
            "TestDrive:\Links\Games\Ubisoft Game Launcher\savegames" | Should -Exist
        }
    }
}