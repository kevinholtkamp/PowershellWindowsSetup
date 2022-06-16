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
    Context "Setup-Hosts"{
        BeforeAll{
            $Env:WinDir = "TestDrive:\Windows"
            New-Item "$($Env:WinDir)\system32\Drivers\etc\hosts" -ItemType File -Force -ErrorAction SilentlyContinue
        }
        AfterAll{
            $Env:WinDir = "C:\Windows"
            Remove-Item "$TestConfiguration\hosts\from-file.txt"
            Remove-Item "$TestConfiguration\hosts\from-url.txt"
        }
        It "Importing hosts from file"{
            Set-Content "$TestConfiguration\hosts\from-file.txt" "192.168.178.1       fritz.box"

            Setup-Hosts -Configuration $TestConfiguration

            Select-String -Path "TestDrive:\Windows\system32\Drivers\etc\hosts" -Pattern "fritz.box" | Should -not -BeNullOrEmpty
        }
        It "Importing hosts from url"{
            Set-Content "$TestConfiguration\hosts\from-url.txt" "https://blocklistproject.github.io/Lists/smart-tv.txt"

            Setup-Hosts -Configuration $TestConfiguration

            Select-String -Path "TestDrive:\Windows\system32\Drivers\etc\hosts" -Pattern "Smart TV list" | Should -not -BeNullOrEmpty
        }
    }
}