BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Set-OptionalFeatures"{
    Context "Set-OptionalFeatures"{
        BeforeAll{
            $EnableFeatures = @{
                "OptionalFeatures" = @{
                    "DirectPlay" = "enable"
                    "TelnetClient" = "enable"
                    "NetFx3" = "enable"
                    "ServicesForNFS-ClientOnly" = "enable"
                    "Internet-Explorer-Optional-amd64" = "enable"
                    "Windows-Defender-ApplicationGuard" = "enable"
                    "Windows-Defender-Default-Definitions" = "enable"
                    "SmbDirect" = "enable"
                    "tftp" = "enable"
                    "MicrosoftWindowsPowerShellV2" = "enable"
                    "MicrosoftWindowsPowerShellV2Root" = "enable"
                    "DirectoryServices-ADAM-Client" = "enable"
                }
            }
            $DisableFeatures = @{
                "OptionalFeatures" = @{
                    "HostGuardian" = "disable"
                }
            }
        }
        It "Enable features"{
            Set-OptionalFeatures -IniContent $EnableFeatures -Verbose

            $EnableFeatures | ForEach-Object {Get-WindowsOptionalFeature -FeatureName $_ -Online | Where-Object {$_.state -eq "Enabled"} | Should -Be $true}
        }
        It "Disable features"{
            Set-OptionalFeatures -IniConten $DisableFeatures

            $EnableFeatures | ForEach-Object {Get-WindowsOptionalFeature -FeatureName $_ -Online | Where-Object {$_.state -eq "Disabled"} | Should -Be $true}
        }
    }
}