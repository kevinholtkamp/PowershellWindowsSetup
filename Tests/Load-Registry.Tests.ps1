BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

Describe "Load-Registry"{
    #ToDo make test non intrusive for host
    Context "Load-Registry"{
        BeforeAll{
            Load-Registry -Group $TestGroup
        }
        It "Import registry keys"{
            Get-ItemPropertyValue -Path "HKCU:\Control Panel\Desktop" -Name "JPEGImportQuality" | Should -Be 100
        }
    }
}