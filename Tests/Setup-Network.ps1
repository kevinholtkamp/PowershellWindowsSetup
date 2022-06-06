BeforeAll {
    . .\Tests\CommonTestParameters.ps1

    . .\setup.ps1
}

Describe "Setup-Network"{
    Context "All Parameters"{
        BeforeAll{
            Mock Remove-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily $Interface["AddressFamily"]
            Mock Remove-NetRoute -InterfaceAlias $InterfaceAlias
            Mock New-NetIPAddress -InterfaceAlias $InterfaceAlias @Interface
            Mock Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $DNSServers.Values
        }
        It "General function"{
            Setup-Network -Group $TestGroup

            Should -Invoke Remove-NetIPAddress -Times 1 -Exactly -ParameterFilter {
                $InterfaceAlias -eq "Ethernet" -and
                $AddressFamily -eq "IPv4"}
            Should -Invoke Remove-NetRoute -Times 1 -Exactly -ParameterFilter {
                $InterfaceAlias -eq "Ethernet"}
            Should -Invoke Remove-NetIPAddress -Times 1 -Exactly -ParameterFilter {
                $InterfaceAlias -eq "WLAN" -and
                $AddressFamily -eq "IPv4"}
            Should -Invoke Remove-NetRoute -Times 1 -Exactly -ParameterFilter {
                $InterfaceAlias -eq "WLAN"}
            Should -Invoke New-NetIPAddress -Times 1 -Exactly -ParameterFilter {
                $InterfaceAlias -eq "Ethernet" -and
                $IPAddress -eq "192.168.86.101" -and
                $AddressFamily -eq "IPv4" -and
                $PrefixLength -eq 24 -and
                $DefaultGateway -eq "192.168.86.1"}
            Should -Invoke -CommandName New-NetIPAddress -Times 1 -Exactly -ParameterFilter {
                $InterfaceAlias -eq "WLAN" -and
                $IPAddress -eq "192.168.86.102" -and
                $AddressFamily -eq "IPv4" -and
                $PrefixLength -eq 24 -and
                $DefaultGateway -eq "192.168.86.1"}
            Should -Invoke Set-DnsClientServerAddress -Times 1 -Exactly -ParameterFilter {
                $InterfaceAlias -eq "Ethernet" -and
                $ServerAddresses -eq @("192.168.86.100", "1.0.0.1")}
            Should -Invoke Set-DnsClientServerAddress -Times 1 -Exactly -ParameterFilter {
                $InterfaceAlias -eq "WLAN" -and
                $ServerAddresses -eq @("192.168.86.100", "1.0.0.1")}
        }
    }
}