BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-Hosts"{
    Context "Setup-Hosts"{
        BeforeAll{
            $Env:WinDir = "TestDrive:\Windows"
            New-Item "$($Env:WinDir)\system32\Drivers\etc\hosts" -ItemType File -Force
            Setup-Hosts -Group $TestGroup
            $Env:WinDir = "C:\Windows"
        }
        It "Importing hosts from file"{
            Select-String -Path "TestDrive:\Windows\system32\Drivers\etc\hosts" -Pattern "fritz.box" | Should -not -BeNullOrEmpty
        }
        It "Importing hosts from url"{
            Select-String -Path "TestDrive:\Windows\system32\Drivers\etc\hosts" -Pattern "Smart TV list" | Should -not -BeNullOrEmpty
        }
    }
}