BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-Powershell"{
    BeforeAll{
        New-Item "$TestConfiguration\powershell" -ItemType Directory -Force -ErrorAction SilentlyContinue
    }
    AfterAll{
        Remove-Item "$TestConfiguration\powershell" -Force -Recurse -ErrorAction SilentlyContinue
    }
    Context "Powershell"{
        BeforeAll{
            Mock Update-Help {}
            Mock Get-InstalledModule {}
            Mock Get-PackageProvider {}
            Mock Install-PackageProvider {}
            Mock Install-Module {}

            Set-Content "$TestConfiguration\powershell\module.txt" "PSWinRAR"
            Set-Content "$TestConfiguration\powershell\packageprovider.txt" "NuGet"
        }
        AfterAll{
            Remove-Item "$TestConfiguration\powershell\module.txt"
            Remove-Item "$TestConfiguration\powershell\packageprovider.txt"
        }
        It "Testing install"{
            Setup-Powershell -Configuration $TestConfiguration

            Should -Invoke Update-Help -Exactly -Times 1
            Should -Invoke Get-PackageProvider -Exactly -Times 1 -ParameterFilter {"NuGet"}
            Should -Invoke Install-PackageProvider -Exactly -Times 1 -ParameterFilter {"NuGet"}
            Should -Invoke Get-InstalledModule -Exactly -Times 1 -ParameterFilter {"PSWinRAR"}
            Should -Invoke Install-Module -Exactly -Times 1 -ParameterFilter {"PSWinRAR"}
        }
    }
}