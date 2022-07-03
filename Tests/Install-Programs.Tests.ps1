BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Install-Programs"{
    function script:Cleanup(){
        Remove-Item "$TestConfiguration\install\test.exe" -ErrorAction SilentlyContinue
        Remove-Item "$TestConfiguration\install\from-url.txt" -ErrorAction SilentlyContinue
        Remove-Item "$TestConfiguration\install\from-chocolatey.txt" -ErrorAction SilentlyContinue
        Remove-Item "$TestConfiguration\install\from-winget.txt" -ErrorAction SilentlyContinue
        Remove-Item "$TestConfiguration\install\chocolatey-repository.ini" -ErrorAction SilentlyContinue
    }
    BeforeEach{
        New-Item "$TestConfiguration\install" -ItemType Directory -Force -ErrorAction Silentlycontinue

        Cleanup
    }
    AfterEach{
        Remove-Item "$TestConfiguration\install" -Force -Recurse -ErrorAction SilentlyContinue

        Cleanup
    }
    Context "Install from URL"{
        BeforeAll{
            Mock Start-Process {}
        }
        It "Normal installation"{
            Set-Content "$TestConfiguration\install\from-url.txt" "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.3.3/npp.8.3.3.Installer.x64.exe"

            Install-Programs -Configuration $TestConfiguration

            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {$FilePath -eq "$($Env:TEMP)\1.exe" -and $ArgumentList -eq "/S" -and $Wait -eq $true}
            "$($Env:TEMP)\1.exe" | Should -Not -Exist
        }
        It "Broken URL"{
            New-Item "$TestConfiguration\install\from-url.txt" -ItemType File
            Set-Content "$TestConfiguration\install\from-url.txt" "https://google.de/file.exe"

            {Install-Programs -Configuration $TestConfiguration} | Should -Throw

            "$($Env:TEMP)\1.exe" | Should -Not -Exist
        }
        It "Non executable file"{
            New-Item "$TestConfiguration\install\from-url.txt" -ItemType File
            Set-Content "$TestConfiguration\install\from-url.txt" "https://github.com/kevinholtkamp/PowershellWindowsSetup/blob/94ba53b8ff6964f338afc169225dcb1a6ced3619/README.md"

            Install-Programs -Configuration $TestConfiguration

            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {$FilePath -eq "$($Env:TEMP)\1.exe"}
            "$($Env:TEMP)\1.exe" | Should -Not -Exist
        }
    }
    Context "Install from exe"{
        It "Regular exe file"{
            $Date = Get-Date
            Copy-Item "C:\Windows\system32\notepad.exe" "$TestConfiguration\install\notepad.exe"
            New-Item "$TestConfiguration\install\de-DE\" -ItemType Directory -Force
            Copy-Item "C:\Windows\system32\de-DE\notepad.exe.mui" "$TestConfiguration\install\de-DE\notepad.exe.mui"

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

            Remove-Item "$TestConfiguration\install\test.exe"
        }
    }
    Context "Install choco"{
        It "Installing choco"{
            Mock Start-Job {0}
            Mock Stop-Job {}

            New-Item "$TestConfiguration\install\from-chocolatey.txt"

            Install-Programs -Configuration $TestConfiguration

            Should -Invoke Start-Job -Times 1 -Exactly
        }
        It "Installing from choco"{
            function script:choco(){}
            Mock choco {}

            New-Item "$TestConfiguration\install\from-chocolatey.txt"
            Set-Content "$TestConfiguration\install\from-chocolatey.txt" "testChocoPackage"

            Install-Programs -Configuration $TestConfiguration

            Should -Invoke choco -Times 3 -Exactly
        }
        It "Chocolatey repository"{
            function script:choco(){}
            Mock choco {}

            New-Item "$TestConfiguration\install\from-chocolatey.txt"
            New-Item "$TestConfiguration\install\chocolatey-repository.ini"
            Set-Content "$TestConfiguration\install\chocolatey-repository.ini" "[chocolatey]
source=https://community.chocolatey.org/api/v2/
priority=1"

            Install-Programs -Configuration $TestConfiguration

            Should -Invoke choco -Times 3 -Exactly
        }
    }
    Context "Winget"{
        It "Install winget"{
            Mock Start-Process {}
            Mock Wait-Process {}

            New-Item "$TestConfiguration\install\from-winget.txt"

            Install-Programs -Configuration $TestConfiguration

            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {$FilePath -eq "ms-appinstaller:?source=https://aka.ms/getwinget"}
        }
        It "Install from winget"{
            function script:winget(){}
            Mock winget {}

            New-Item "$TestConfiguration\install\from-winget.txt"
            Set-Content "$TestConfiguration\install\from-winget.txt" "wingetTestPackage"

            Install-Programs -Configuration $TestConfiguration

            Should -Invoke winget -Times 1 -Exactly
        }
    }
}