BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Set-OptionalFeatures"{
    Context "Set-OptionalFeatures"{
        BeforeAll{
            Mock Enable-WindowsOptionalFeature{}
            Mock Disable-WindowsOptionalFeature{}
        }
        It "Enable features"{
            Mock Get-WindowsOptionalFeature {
                @(
                    @{
                        FeatureName = $FeatureName
                        state = "Disabled"
                    }
                )
            }
            $EnableFeatures = @{
                "OptionalFeatures" = @{
                    "DirectPlay" = "Enable"
                    "TelnetClient" = "Enable"
                    "NetFx3" = "Enable"
                    "ServicesForNFS-ClientOnly" = "Enable"
                    "Internet-Explorer-Optional-amd64" = "Enable"
                    "Windows-Defender-ApplicationGuard" = "Enable"
                    "Windows-Defender-Default-Definitions" = "Enable"
                    "SmbDirect" = "Enable"
                    "tftp" = "Enable"
                    "MicrosoftWindowsPowerShellV2" = "Enable"
                    "MicrosoftWindowsPowerShellV2Root" = "Enable"
                    "DirectoryServices-ADAM-Client" = "Enable"
                }
            }

            Set-OptionalFeatures -IniContent $EnableFeatures

#            $EnableFeatures | ForEach-Object {Get-WindowsOptionalFeature -FeatureName $_ -Online | Where-Object {$_.state -eq "Enabled"} | Should -Be $true}
#            Should -Invoke -CommandName Enable-WindowsOptionalFeature -Exactly -Times 12
        }
        It "Disable features"{
            Mock Get-WindowsOptionalFeature {
                @(
                    @{
                        FeatureName = $FeatureName
                        state = "Enabled"
                    }
                )
            }
            $DisableFeatures = @{
                "OptionalFeatures" = @{
                    "HostGuardian" = "Disable"
                }
            }

            Set-OptionalFeatures -IniConten $DisableFeatures

#            $EnableFeatures | ForEach-Object {Get-WindowsOptionalFeature -FeatureName $_ -Online | Where-Object {$_.state -eq "Disabled"} | Should -Be $true}
#            Should -Invoke -CommandName Enable-WindowsOptionalFeature -Exactly -Times 1
        }
    }
}