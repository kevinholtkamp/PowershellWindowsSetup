BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

Describe "Remove-Bloatware"{
    Context "Test with bloatware"{
        BeforeAll{
            Mock Get-AppxPackage {
                if("Candy Crush" -like $Name){
                    return "Candy Crush"
                }
                elseif("King" -like $Name){
                    return "King"
                }
                elseif("Xing" -like $Name){
                    return "Xing"
                }
            }
            Mock Remove-AppxPackage {}
        }
        It "Remove mocked bloatware"{
            Remove-Bloatware -Group $TestGroup
            Should -Invoke Remove-AppxPackage -Times 1 -ParameterFilter {"Candy Crush"}
            Should -Invoke Remove-AppxPackage -Times 1 -ParameterFilter {"King"}
            Should -Invoke Remove-AppxPackage -Times 1 -ParameterFilter {"Xing"}
            Should -Invoke Remove-AppxPackage -Exactly -Times 3
        }
    }
}