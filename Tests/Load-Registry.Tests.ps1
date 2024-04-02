BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Load-Registry"{
    BeforeEach{
        Get-ChildItem "TestRegistry:\" -Recurse | Remove-Item
    }
    Context "RegistryData parameter"{
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
}