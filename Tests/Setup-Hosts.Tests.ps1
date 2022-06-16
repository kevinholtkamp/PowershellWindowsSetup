BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-Hosts"{
    Context "Setup-Hosts"{
        BeforeAll{
            $Env:WinDir = "TestDrive:\Windows"
            New-Item "$($Env:WinDir)\system32\Drivers\etc\hosts" -ItemType File -Force -ErrorAction SilentlyContinue
        }
        AfterAll{
            $Env:WinDir = "C:\Windows"
            Remove-Item "$TestGroup\hosts\from-file.txt"
            Remove-Item "$TestGroup\hosts\from-url.txt"
        }
        It "Importing hosts from file"{
            Set-Content "$TestGroup\hosts\from-file.txt" "192.168.178.1       fritz.box"

            Setup-Hosts -Group $TestGroup

            Select-String -Path "TestDrive:\Windows\system32\Drivers\etc\hosts" -Pattern "fritz.box" | Should -not -BeNullOrEmpty
        }
        It "Importing hosts from url"{
            Set-Content "$TestGroup\hosts\from-url.txt" "https://blocklistproject.github.io/Lists/smart-tv.txt"

            Setup-Hosts -Group $TestGroup

            Select-String -Path "TestDrive:\Windows\system32\Drivers\etc\hosts" -Pattern "Smart TV list" | Should -not -BeNullOrEmpty
        }
    }
}