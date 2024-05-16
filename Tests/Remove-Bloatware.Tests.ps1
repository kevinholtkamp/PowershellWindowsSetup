BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Remove-Bloatware"{
    It "Empty parameter"{
        Mock Remove-AppxPackage {}

        Remove-Bloatware -Bloatware @()

        Should -Invoke -CommandName Remove-AppxPackage -Exactly -Times 0
    }
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
            Remove-Bloatware -Bloatware @("*candy*", "*king*", "*xing*")

            Should -Invoke Remove-AppxPackage -Times 1 -ParameterFilter {"Candy Crush"}
            Should -Invoke Remove-AppxPackage -Times 1 -ParameterFilter {"King"}
            Should -Invoke Remove-AppxPackage -Times 1 -ParameterFilter {"Xing"}
            Should -Invoke Remove-AppxPackage -Times 3 -Exactly
        }
        It "Try removing not installed app"{
            {Remove-Bloatware -Bloatware @("", "awdawdad")} | Should -Throw
        }
        It "-Bloatware Parameter"{
            Remove-Bloatware -Bloatware "Candy Crush"

            Should -Invoke Remove-AppxPackage -Times 1 -ParameterFilter {"Candy Crush"}
        }
    }
}