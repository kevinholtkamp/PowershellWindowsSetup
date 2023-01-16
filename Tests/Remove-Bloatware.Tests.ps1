BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Remove-Bloatware"{
    BeforeAll{
        New-Item "$TestConfiguration\install" -ItemType Directory -Force -ErrorAction Silentlycontinue
    }
    AfterAll{
        Remove-Item "$TestConfiguration\install" -Force -Recurse -ErrorAction SilentlyContinue
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
        AfterAll{
            Remove-Item "$TestConfiguration\install\remove-bloatware.txt"
        }
        It "Remove mocked bloatware"{
            Set-Content "$TestConfiguration\install\remove-bloatware.txt" "*candy*"
            Add-Content "$TestConfiguration\install\remove-bloatware.txt" "*king*"
            Add-Content "$TestConfiguration\install\remove-bloatware.txt" "*xing*"

            Remove-Bloatware -Configuration $TestConfiguration

            Should -Invoke Remove-AppxPackage -Times 1 -ParameterFilter {"Candy Crush"}
            Should -Invoke Remove-AppxPackage -Times 1 -ParameterFilter {"King"}
            Should -Invoke Remove-AppxPackage -Times 1 -ParameterFilter {"Xing"}
            Should -Invoke Remove-AppxPackage -Times 3 -Exactly
        }
        It "Try removing not installed app"{
            Set-Content "$TestConfiguration\install\remove-bloatware.txt" ""
            Add-Content "$TestConfiguration\install\remove-bloatware.txt" "awdawdad"

            {Remove-Bloatware -Configuration $TestConfiguration} | Should -Throw
        }
        It "-Bloatware Parameter"{
            Remove-Bloatware -Configuration "" -Bloatware "Candy Crush"

            Should -Invoke Remove-AppxPackage -Times 1 -ParameterFilter {"Candy Crush"}
        }
    }
}