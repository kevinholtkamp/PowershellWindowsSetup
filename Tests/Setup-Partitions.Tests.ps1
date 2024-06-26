BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-Partitions"{
    It "Empty parameter"{
        Mock Set-Partition {}

        Setup-Partitions -IniContent @{}

        Should -Invoke -CommandName Set-Partition -Exactly -Times 0
    }
    BeforeAll{
        New-Item "$TestConfiguration\settings" -ItemType Directory -Force -ErrorAction SilentlyContinue
    }
    AfterAll{
        Remove-Item "$TestConfiguration\settings" -Force -Recurse -ErrorAction SilentlyContinue
    }
    Context "Should-work test"{
        BeforeAll{
            Mock Set-Partition {
                Write-Information "------"
                Write-Information "Partition: $($InputObject.PartitionNumber)"
                Write-Information "Disk Number: $($InputObject.DriveNumber)"
                Write-Information "DriveLetter: $NewDriveLetter"
                Write-Information "------"
            }
        }
        AfterAll{
            Remove-Item "$TestConfiguration\settings\partitions.ini"
        }
        It "Dynamic test with Serial Number '<SerialNumber>' and drive letters (<Letters>)" -ForEach @(
            @{ SerialNumber = "SERIAL"; Letters = @("A", "B") }
            @{ SerialNumber = "SERIAL"; Letters = @("C") }
            @{ SerialNumber = "SERIAL"; Letters = @("F", "X") }
            @{ SerialNumber = "SERIAL"; Letters = @() }
            @{ SerialNumber = ""; Letters = @("F", "X") }
            @{ SerialNumber = ""; Letters = @() }
        ) {
            $GetDiskScriptblock = [Scriptblock]::Create("
                    `$Result = [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_Disk','root/Microsoft/Windows/Storage');
                    `$Result | Add-Member -Name SerialNumber -Value '$($SerialNumber)' -MemberType NoteProperty;
                    `$Result | Add-Member -Name DriveNumber -Value 1 -MemberType NoteProperty;
                    return `$Result;")
            $GetPartitionScriptblock = [Scriptblock]::Create("
                `$Ret = [System.Collections.ArrayList]@();
                `$Index = 1;
                foreach(`$Letter in $("@($($Letters | ForEach-Object {"'$_'"} | Join-StringCustom -Separator ','))")){
                    `$Part = [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_Partition', 'root/Microsoft/Windows/Storage')
                    `$Part | Add-Member -Name PartitionNumber -Value `$Index -MemberType NoteProperty;
                    `$Part | Add-Member -Name DriveNumber -Value `$Disk.DriveNumber -MemberType NoteProperty;
                    `$Ret.Add(`$Part);
                    `$Index = `$Index + 1;
                }
                return `$Ret;")
            Mock Get-Disk $GetDiskScriptblock
            Mock Get-Partition $GetPartitionScriptblock

            $IniContent = @{$SerialNumber = @{}}
            $Index = 1
            foreach($Letter in $Letters) {
                $IniContent[$SerialNumber][$Index] = $Letter
                $Index = $index + 1
            }
            Setup-Partitions -IniContent $IniContent

            Should -Invoke -CommandName Set-Partition -Exactly -Times ($Letters.Length * 2)
            $Index = 1
            foreach($Letter in $Letters){
                $ParameterfilterScriptblock = [Scriptblock]::Create("{`$InputObject.DriveNumber -eq 1 -and `$InputObject.PartitionNumber -eq $Index -and `$NewDriveLetter -eq '$($Letters[$Index])'}")
                Should -Invoke -CommandName Set-Partition -Times 1 -Parameterfilter $ParameterfilterScriptblock
                $Index = $Index + 1
            }
        }
    }
    Context "Should-fail test"{

    }
}