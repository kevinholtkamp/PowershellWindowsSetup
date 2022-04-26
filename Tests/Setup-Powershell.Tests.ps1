BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-Powershell"{
    #ToDo make test non intrusive for host
    Context "Setup-Powershell"{
        BeforeAll{
            Setup-Powershell -Group $TestGroup
        }
        #ToDo remove Nuget and Recycle if they weren't installed before
        It "PackageProvider NuGet"{
            Get-PackageProvider *NuGet* | Should -Be $true
        }
        It "Module PSWinRAR"{
            Get-InstalledModule *PSWinRAR* | Should -Be $true
        }
    }
}