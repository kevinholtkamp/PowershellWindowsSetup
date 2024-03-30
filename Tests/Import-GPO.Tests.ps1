BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Import-GPO"{
    Context "Import-GPO"{
        BeforeAll{
            Set-Content ".\$TestConfiguration\settings\gpedit.txt" ""
        }
        It "Test"{
            Import-GPO -Configuration $TestConfiguration
        }
    }
}