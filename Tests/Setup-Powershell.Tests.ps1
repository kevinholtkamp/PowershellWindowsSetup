BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-Powershell"{
    It "Empty parameter"{
        Mock Update-Help {}
        Mock Install-PackageProvider {}
        Mock Install-Module {}

        Setup-Powershell -Modules @() -PackageProviders @()

        Should -Invoke -CommandName Update-Help -Exactly -Times 1
        Should -Invoke -CommandName Install-PackageProvider -Exactly -Times 0
        Should -Invoke -CommandName Install-Module -Exactly -Times 0
    }
    BeforeAll{
        New-Item "$TestConfiguration\powershell" -ItemType Directory -Force -ErrorAction SilentlyContinue
    }
    AfterAll{
        Remove-Item "$TestConfiguration\powershell" -Force -Recurse -ErrorAction SilentlyContinue
    }
    Context "PackageProvider parameter"{
        BeforeAll{
            Mock Update-Help {}
            Mock Get-InstalledModule {}
            Mock Get-PackageProvider {}
            Mock Install-PackageProvider {}
            Mock Install-Module {}
        }
        It "Testing install"{
            Setup-Powershell -PackageProvider @("NuGet")

            Should -Invoke Update-Help -Exactly -Times 1
            Should -Invoke Get-PackageProvider -Exactly -Times 1 -ParameterFilter {"NuGet"}
            Should -Invoke Install-PackageProvider -Exactly -Times 1 -ParameterFilter {"NuGet"}
        }
    }
    Context "Modules parameter"{
        BeforeAll{
            Mock Update-Help {}
            Mock Get-InstalledModule {}
            Mock Get-PackageProvider {}
            Mock Install-PackageProvider {}
            Mock Install-Module {}
        }
        It "Testing install"{
            Setup-Powershell -Modules @("PSWinRAR", "NuGet")

            Should -Invoke Update-Help -Exactly -Times 1
            Should -Invoke Get-InstalledModule -Exactly -Times 2 -ParameterFilter {"PSWinRAR"}
            Should -Invoke Install-Module -Exactly -Times 2 -ParameterFilter {"PSWinRAR"}
        }
    }
}