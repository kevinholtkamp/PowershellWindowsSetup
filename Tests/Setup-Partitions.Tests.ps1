BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-Partitions"{
    Context "Setup-Partitions"{
        BeforeAll{
            Mock Get-Disk {
                $Result = [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_Disk','root/Microsoft/Windows/Storage')
                $Result | Add-Member -Name SerialNumber -Value 'SERIAL' -MemberType NoteProperty
                Return $Result
            }
            Mock Get-Partition {
                return @(
                ([Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_Partition','root/Microsoft/Windows/Storage') | Add-Member -Name PartitionNumber -Value 1 -MemberType NoteProperty -PassThru),
                ([Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_Partition','root/Microsoft/Windows/Storage') | Add-Member -Name PartitionNumber -Value 2 -MemberType NoteProperty -PassThru)
                )

            }
            Mock Set-Partition {}
        }
        AfterAll{
            Remove-Item "$TestGroup\settings\partitions.ini"
        }
        It "Set mock partitions"{
            Set-Content "$TestGroup\settings\partitions.ini" "[SERIAL]
1=A
2=B"

            Setup-Partitions -Group $TestGroup
            Should -Invoke -CommandName Set-Partition -Times 4 -Exactly
#            Should -Invoke -CommandName Set-Partition -Times 1 -Exactly -ParameterFilter { $InputObject.PartitionNumber -eq 1 -and $NewDriveLetter -eq "D" }
#            Should -Invoke -CommandName Set-Partition -Times 1 -Exactly -ParameterFilter { $InputObject.PartitionNumber -eq 2 -and $NewDriveLetter -eq "E" }
#            Should -Invoke -CommandName Set-Partition -Times 1 -Exactly -ParameterFilter { $InputObject.PartitionNumber -eq 1 -and $NewDriveLetter -eq "A" }
#            Should -Invoke -CommandName Set-Partition -Times 1 -Exactly -ParameterFilter { $InputObject.PartitionNumber -eq 2 -and $NewDriveLetter -eq "B" }
#            Assert-MockCalled Set-Partition -Times 1 -Exactly -ParameterFilter { $NewDriveLetter -eq "D" }
#            Assert-MockCalled Set-Partition -Times 1 -Exactly -ParameterFilter { $NewDriveLetter -eq "E" }
#            Assert-MockCalled Set-Partition -Times 1 -Exactly -ParameterFilter { $NewDriveLetter -eq "A" }
#            Assert-MockCalled Set-Partition -Times 1 -Exactly -ParameterFilter { $NewDriveLetter -eq "B" }
        }
    }
}