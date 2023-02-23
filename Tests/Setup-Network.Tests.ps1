BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-Network"{
    BeforeAll{
        New-Item "$TestConfiguration\network" -ItemType Directory

        Mock Remove-NetIPAddress {
            Write-Information "------"
            Write-Information "Remove-NetIPAddress:"
            Write-Information "InterfaceAlias: $InterfaceAlias"
            Write-Information "AddressFamily: $AddressFamily"
            Write-Information "------"
        }
        Mock Remove-NetRoute {
            Write-Information "------"
            Write-Information "Remove-NetRoute:"
            Write-Information "InterfaceAlias: $InterfaceAlias"
            Write-Information "------"
        }
        Mock New-NetIPAddress {
            Write-Information "------"
            Write-Information "New-NetIPAddress:"
            Write-Information "InterfaceAlias: $InterfaceAlias"
            Write-Information "IPAddress: $IPAddress"
            Write-Information "Address-Family: $AddressFamily"
            Write-Information "PrefixLength: $PrefixLength"
            Write-Information "DefaultGateway: $DefaultGateway"
            Write-Information "------"
        }
        Mock Set-DnsClientServerAddress {
            Write-Information "------"
            Write-Information "Set-DnsClientServerAddress"
            Write-Information "InterfaceAlias: $InterfaceAlias"
            Write-Information "ServerAddresses: $ServerAddresses"
            Write-Information "------"
        }
    }
    AfterAll{
        Remove-Item "$TestConfiguration\network" -Recurse -Force
    }
    Context "All Parameters"{
        It "General function" -ForEach @(
            @{
                DNS = @{
                    Ethernet = @{
                        Primary = "192.168.86.100";
                        Secondary = "1.0.0.1"
                    };
                    WLAN = @{
                        Primary = "192.168.86.100";
                        Secondary = "1.0.0.1"
                    }
                }
                Interfaces = @{
                    Ethernet = @{
                        IPAddress = "192.168.86.101";
                        AddressFamily = "IPv4";
                        PrefixLength = 24;
                        DefaultGateway = "192.168.86.1"
                    };
                    WLAN = @{
                        IPAddress = "192.168.86.102";
                        AddressFamily = "IPv4";
                        PrefixLength = 24;
                        DefaultGateway = "192.168.86.1"
                    }
                }
            }
        ){
            Out-IniFile -FilePath "$TestConfiguration\network\interfaces.ini" -InputObject $Interfaces
            Out-IniFile -FilePath "$TestConfiguration\network\dns.ini" -InputObject $DNS

            Setup-Network -Configuration $TestConfiguration -Verbose

            #Remove-NetIPAddress
            #Remove-NetRoute
            foreach($Interface in $Interfaces.Keys){
                $ParameterFilterScriptblock = [ScriptBlock]::Create(
                    "`$InterfaceAlias -eq '$Interface' -and `$AddressFamily -eq '$($Interfaces[$Interface].AddressFamily)'"
                )
                Should -Invoke Remove-NetIPAddress -Times 1 -Exactly -ParameterFilter $ParameterFilterScriptblock

                $ParameterFilterScriptblock = [ScriptBlock]::Create("`$InterfaceAlias -eq '$Interface'")
                Should -Invoke Remove-NetRoute -Times 1 -Exactly -ParameterFilter $ParameterFilterScriptblock
            }
            #New-NetIPAddress
            foreach($Interface in $Interfaces.Keys){
                $ParameterFilterScriptblock = [ScriptBlock]::Create(
                    "`$InterfaceAlias -eq '$Interface' ``
                    -and `$IPAddress -eq '$($Interfaces[$Interface].IPAddress)' ``
                    -and `$AddressFamily -eq '$($Interfaces[$Interface].AddressFamily)' ``
                    -and `$PrefixLength -eq '$($Interfaces[$Interface].PrefixLength)' ``
                    -and `$DefaultGateway -eq '$($Interfaces[$Interface].DefaultGateway)'"
                )
                Should -Invoke New-NetIPAddress -Times 1 -Exactly -ParameterFilter $ParameterFilterScriptblock
            }
            #Set-DnsClientServerAddress
            foreach($Interface in $DNS.Keys){
                $ParameterFilterScriptblock = [ScriptBlock]::Create("
                    `$InterfaceAlias -eq '$Interface' -and -not (Compare-Object `$ServerAddresses @($($DNS[$Interface].Values | ForEach-Object {"'$_'"} | Join-StringCustom -Separator ',')))")
                Should -Invoke Set-DnsClientServerAddress -Times 1 -Exactly -ParameterFilter $ParameterFilterScriptblock
            }
        }
    }
}