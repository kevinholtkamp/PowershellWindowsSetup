BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-Hosts"{
    BeforeAll{
        New-Item "$TestConfiguration\hosts" -ItemType Directory -Force -ErrorAction SilentlyContinue
    }
    AfterAll{
        Remove-Item "$TestConfiguration\hosts" -Force -Recurse -ErrorAction SilentlyContinue
    }
    Context "Powershell parameters"{
        BeforeAll{
            $Env:WinDir = "TestDrive:\Windows"
            New-Item "$($Env:WinDir)\system32\Drivers\etc\hosts" -ItemType File -Force -ErrorAction SilentlyContinue
        }
        AfterAll{
            $Env:WinDir = "C:\Windows"
        }
        It "Importing hosts from file"{
            Setup-Hosts -Hosts "192.168.178.1       fritz.box"

            Select-String -Path "TestDrive:\Windows\system32\Drivers\etc\hosts" -Pattern "fritz.box" | Should -not -BeNullOrEmpty
        }
        It "Importing hosts from url"{
            Setup-Hosts -FromURL "https://blocklistproject.github.io/Lists/smart-tv.txt"

            Select-String -Path "TestDrive:\Windows\system32\Drivers\etc\hosts" -Pattern "Smart TV list" | Should -not -BeNullOrEmpty
        }
    }
}