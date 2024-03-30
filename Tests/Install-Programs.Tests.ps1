BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Install-Programs"{
    Context "Install from exe"{
        BeforeAll{
            New-Item "$TestConfiguration\install\" -ItemType Directory -Force
        }
        AfterAll{
            Remove-Item "$TestConfiguration\install\" -Force -ErrorAction "SilentlyContinue"
        }
        It "Regular exe file"{
            $Date = Get-Date
            Copy-Item "C:\Windows\system32\notepad.exe" "$TestConfiguration\install\notepad.exe" -Force
            New-Item "$TestConfiguration\install\de-DE\" -ItemType Directory -Force
            Copy-Item "C:\Windows\system32\de-DE\notepad.exe.mui" "$TestConfiguration\install\de-DE\notepad.exe.mui" -Force

            Install-Programs -Configuration $TestConfiguration

#            Get-Process -name "notepad" | Where-Object -Property starttime -ge $Date | Should -Not -Be $null
            $Process = Get-Process -name "notepad" | Where-Object -Property starttime -ge $Date
            $Process | Should -Not -Be $null
            Stop-Process $Process -Force
            Wait-Process $Process
            $Process.HasExited | Should -Be $true

            Remove-Item "$TestConfiguration\install\notepad.exe" -Force
            Remove-Item "$TestConfiguration\install\de-DE\notepad.exe.mui" -Force
            Remove-Item "$TestConfiguration\install\de-DE" -Force
        }
        It "Fake exe file"{
            Mock Start-Process {}

            New-Item "$TestConfiguration\install\test.exe" -ItemType File

            Install-Programs -Configuration $TestConfiguration

#            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {$FilePath -like "*$TestConfiguration\install\test.exe" -and $ArgumentList -eq "/S" -and $Wait -eq $true}
            Should -Invoke Start-Process -Times 1 -Exactly #-ParameterFilter {$ArgumentList -eq "/S" -and $Wait -eq $true}

            Remove-Item "$TestConfiguration\install\test.exe" -Force
        }
    }
    Context "Install from URL"{
        BeforeAll{
            Mock Start-Process {}
        }
        It "Normal installation"{
            Install-Programs -FromURL "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.3.3/npp.8.3.3.Installer.x64.exe"

            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {$FilePath -eq "$($Env:TEMP)\1.exe" -and $ArgumentList -eq "/S" -and $Wait -eq $true}
            "$($Env:TEMP)\1.exe" | Should -Not -Exist
        }
        It "Broken URL"{
            {
                Install-Programs -FromURL "https://google.de/file.exe"
            } | Should -Throw

            "$($Env:TEMP)\1.exe" | Should -Not -Exist
        }
        It "Non executable file"{
            Install-Programs -FromURL "https://github.com/kevinholtkamp/PowershellWindowsSetup/blob/94ba53b8ff6964f338afc169225dcb1a6ced3619/README.md"

            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {$FilePath -eq "$($Env:TEMP)\1.exe"}
            "$($Env:TEMP)\1.exe" | Should -Not -Exist
        }
    }
    Context "Install from choco"{
        It "Installing choco"{
            Mock Start-Job {0}
            Mock Stop-Job {}

            Install-Choco

            Should -Invoke Start-Job -Times 1 -Exactly
        }
        It "Installing choco repositories"{
            function script:choco(){}
            Mock choco {}

            Install-Choco -Sources @{
                "chocolatey" = @{
                    "source" = "https://community.chocolatey.org/api/v2/"
                    "priority" = "0"
                }
            }

            Should -Invoke choco -Times 3 -Exactly
        }
        It "Installing from choco"{
            function script:choco(){}
            Mock choco {}

            Install-Choco -Packages "testChocoPackage"

            Should -Invoke choco -Times 3 -Exactly
        }
    }
    Context "Install from winget"{
        It "Install winget"{
            Mock Start-Process {}
            Mock Wait-Process {}

            Install-Winget

            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {$FilePath -eq "ms-appinstaller:?source=https://aka.ms/getwinget"}
        }
        It "Install from winget"{
            function script:winget(){}
            Mock winget {}

            Install-Winget -Packages "wingetTestPackage"

            Should -Invoke winget -Times 1 -Exactly
        }
    }
}