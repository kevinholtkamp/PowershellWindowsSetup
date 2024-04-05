BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Load-Registry"{
    BeforeEach{
        Get-ChildItem "TestRegistry:\" -Recurse | Remove-Item
    }
    It "Empty parameter"{
        Mock New-Item {}
        Mock New-ItemProperty {}
        Mock Set-ItemProperty {}
        Mock Remove-ItemProperty {}

        Load-Registry -RegistryData @{}

        Should -Invoke -CommandName New-Item -Exactly -Times 0
        Should -Invoke -CommandName New-ItemProperty -Exactly -Times 0
        Should -Invoke -CommandName Set-ItemProperty -Exactly -Times 0
        Should -Invoke -CommandName Remove-ItemProperty -Exactly -Times 0
    }
    It "Creating test key"{
        $HashTable = @{
            "TestRegistry:\TestLocation" = @{
                "TestKey" = "TestValue"
            }
        }
        New-Item -Path "TestRegistry:\TestLocation" -ItemType Directory
        Load-Registry -RegistryData $HashTable

        $ItemProperty = Get-ItemProperty -Path "TestRegistry:\TestLocation" -Name "TestKey"
        Write-Host "ItemProperty: $ItemProperty"
        $ItemProperty | Select-Object -ExpandProperty "TestKey" | Should -Be "TestValue"
    }
}