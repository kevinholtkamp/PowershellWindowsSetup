BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

Describe "Install-Programs"{
    Context "Install from URL"{
        BeforeAll{
            Mock Start-Process {}
        }
        It "Tests"{
            Install-Programs -Group $TestGroup
            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {$FilePath -eq "$($Env:TEMP)\1.exe"}
            "$($Env:TEMP)\1.exe" | Should -Not -Exist
        }
    }
    Context "Install from exe"{
        It "Not implemented"{
            $implemented | Should -Be $true
        }
    }
    Context "Install from choco"{
        It "Not implemented"{
            $implemented | Should -Be $true
        }
    }
    Context "Install from winget"{
        It "Not implemented"{
            $implemented | Should -Be $true
        }
    }
}