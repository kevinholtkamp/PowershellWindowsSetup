BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

Describe "Install-Programs"{
    Context "Install-Programs"{
        BeforeAll{
            Mock Start-Process {}
            function choco(){}
            function winget(){}
        }
        It "New"{
            Install-Programs -Group $TestGroup
            #Install Notepad
            Should -Invoke -CommandName Start-Process -Times 1 -Exactly -ParameterFilter {$FilePath -eq "$($Env:TEMP)\1.exe"}
            #Global confirmation, 2x for source, 4x for install / pin
            Should -Invoke -CommandName choco -Times 7 -Exactly -ParameterFiler {}
            #Winget install
            Should -Invoke -CommandName winget -Times 2 -Exactly
        }
    }
}