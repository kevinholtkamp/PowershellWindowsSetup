BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Load-Registry"{
    BeforeEach{
        Get-ChildItem "TestRegistry:\" -Recurse | Remove-Item
    }
    Context "RegistryData parameter"{
        It "Creating test key"{
            $Array = @{
                "TestRegistry:\TestLocation" = @{
                    "TestKey" = "TestValue"
                }
            }
            Load-Registry -RegistryData $Array

            $ItemProperty = Get-ItemProperty -Path "TestRegistry:\TestLocation" -Name "TestKey"
            Write-Host "ItemProperty: $ItemProperty"
            $ItemProperty | Select-Object -ExpandProperty "TestKey" | Should -Be "TestValue"
        }
    }
    Context "RegistryFile parameter"{
        It "Create test key"{
            $Array = @("Windows Registry Editor Version 5.00", "[TestRegistry\TestLocation]", '["TestKey":"TestValue"]')
            Load-Registry -RegistryFile $Array

            $ItemProperty = Get-ItemProperty -Path "TestRegistry:\TestLocation" -Name "TestKey"
            Write-Host "ItemProperty: $ItemProperty"
            $ItemProperty | Select-Object -ExpandProperty "TestKey" | Should -Be "TestValue"
        }
    }
}