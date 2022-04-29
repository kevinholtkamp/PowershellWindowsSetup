BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-Powershell"{
    Context "Powershell"{
        BeforeAll{
            Mock Update-Help {}
            Mock Get-InstalledModule {}
            Mock Get-PackageProvider {}
            Mock Install-PackageProvider {}
            Mock Install-Module {}
        }
        It "Testing install"{
            Setup-Powershell -Group $TestGroup
            Should -Invoke Update-Help -Exactly -Times 1
            Should -Invoke Install-PackageProvider -Exactly -Times 1 -ParameterFilter {"NuGet"}
            Should -Invoke Get-PackageProvider -Exactly -Times 1 -ParameterFilter {"NuGet"}
            Should -Invoke Get-InstalledModule -Exactly -Times 1 -ParameterFilter {"PSWinRAR"}
            Should -Invoke Install-Module -Exactly -Times 1 -ParameterFilter {"PSWinRAR"}
        }
    }
}