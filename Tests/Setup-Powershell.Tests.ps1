BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-Powershell"{
    Context "Setup-Powershell"{
        BeforeAll{
            $DebugPreference = "continue"
            Setup-Powershell -Group $TestGroup
            $DebugPreference = "silentlycontinue"
        }
        #ToDo remove Nuget and Recycle if they weren't installed before
        It "PackageProvider NuGet"{
            Get-PackageProvider *NuGet* | Should -Be $true
        }
        It "Module Recycle"{
            Get-InstalledModule *Recycle* | Should -Be $true
        }
    }
}