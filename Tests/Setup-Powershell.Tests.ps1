BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-Powershell"{
    Context "Setup-Powershell"{
        BeforeAll{
            $DebugPreference = "continue"
            Setup-Powershell -Configuration $TestConfiguration
            $DebugPreference = "silentlycontinue"
        }
        It "PackageProvider NuGet"{
            Get-PackageProvider *NuGet* | Should -Be $true
        }
        It "Module Recycle"{
            Get-InstalledModule *Recycle* | Should -Be $true
        }
    }
}