BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-Hosts"{
    Context "Setup-Hosts"{
        BeforeAll{
            $DebugPreference = "continue"
            Setup-Hosts -Configuration $TestConfiguration
            $DebugPreference = "silentlycontinue"
        }
        It "Importing hosts from file"{
            Select-String -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Pattern "fritz.box" | Should -not -BeNullOrEmpty
        }
        It "Importing hosts from url"{
            Select-String -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Pattern "Smart TV list" | Should -not -BeNullOrEmpty
        }
    }
}