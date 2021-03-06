BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

Describe "Install-Programs"{
    Context "Install-Programs"{
        BeforeAll{
            $DebugPreference = "continue"
            Install-Programs -Configuration $TestConfiguration
            $DebugPreference = "silentlycontinue"
        }
        #ToDo Test for chocolatey Repository
        #From chocolatey
        It "Installed Steam from chocolatey"{
            "C:\Program Files (x86)\Steam\steam" | Should -Exist
        }
        It "Installed git from chocolatey"{
            "C:\Program Files\Git" | Should -Exist
        }
        #From url
        It "Installed notepad++ from url"{
            "C:\Program Files\Notepad++" | Should -Exist
        }
        #From winget
        It "Installed PuTTY from winget"{
            "C:\Program Files\PuTTY" | Should -Exist
        }
        It "Installed WinRAR from winget"{
            "C:\Program Files\WinRAR" | Should -Exist
        }
    }
}