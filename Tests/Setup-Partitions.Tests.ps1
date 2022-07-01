BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-Partitions"{
    BeforeAll{
        New-Item "$TestConfiguration\settings" -ItemType Directory -Force -ErrorAction SilentlyContinue
    }
    AfterAll{
        Remove-Item "$TestConfiguration\settings" -Force -Recurse -ErrorAction SilentlyContinue
    }
    Context "Setup-Partitions"{
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
        It "Dynamic should-work-test with Serial Number '<SerialNumber>' and drive letters (<Letters>)" -ForEach @(
            @{ SerialNumber = "SERIAL"; Letters = @("A", "B") }
            @{ SerialNumber = "SERIAL"; Letters = @("C") }
            @{ SerialNumber = "SERIAL"; Letters = @("F", "X") }
            @{ SerialNumber = "SERIAL"; Letters = @() }
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
            Set-Content "$TestConfiguration\settings\partitions.ini" "[$($SerialNumber)]"
            $Index = 1
            foreach($Letter in $Letters){
                Add-Content "$TestConfiguration\settings\partitions.ini" "$Index=$Letter"
                $Index = $Index + 1
            }

            $InformationPreference = "continue"
            $VerbosePreference = "continue"
            Setup-Partitions -Configuration $TestConfiguration

            Should -Invoke -CommandName Set-Partition -Exactly -Times ($Letters.Length * 2)
            Should -Invoke -CommandName Set-Partition -Times 1 -Parameterfilter {$InputObject.DriveNumber -eq 1 -and $InputObject.PartitionNumber -eq 1 -and $NewDriveLetter -eq "A"}
            Should -Invoke -CommandName Set-Partition -Times 1 -Parameterfilter {$InputObject.DriveNumber -eq 1 -and $InputObject.PartitionNumber -eq 2 -and $NewDriveLetter -eq "B"}
        }
        It "Dynamic should-fail-test with Serial Number '<SerialNumber>' and drive letters (<Letters>)" -ForEach @(
            @{ SerialNumber = ""; Letters = @("F", "X") }
        ) {
            $GetDiskScriptblock = [Scriptblock]::Create("
                    `$Result = [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_Disk','root/Microsoft/Windows/Storage');
                    `$Result | Add-Member -Name SerialNumber -Value '$($SerialNumber)' -MemberType NoteProperty;
                    return `$Result;")
            $GetPartitionScriptblock = [Scriptblock]::Create("
                `$Ret = [System.Collections.ArrayList]@();
                `$Index = 1;
                foreach(`$Letter in $("@($($Letters | ForEach-Object {"'$_'"} | Join-StringCustom -Separator ','))")){
                    `$Ret.Add(([Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_Partition', 'root/Microsoft/Windows/Storage') | Add-Member -Name PartitionNumber -Value `$Index -MemberType NoteProperty -PassThru));
                    `$Index = `$Index + 1;
                }
                return `$Ret;")
            Mock Get-Disk $GetDiskScriptblock
            Mock Get-Partition $GetPartitionScriptblock
            Set-Content "$TestConfiguration\settings\partitions.ini" "[$($SerialNumber)]"
            $Index = 1
            foreach($Letter in $Letters){
                Add-Content "$TestConfiguration\settings\partitions.ini" "$Index=$Letter"
                $Index = $Index + 1
            }

            $InformationPreference = "continue"
            {Setup-Partitions -Configuration $TestConfiguration} | Should -Throw
        }
    }
}