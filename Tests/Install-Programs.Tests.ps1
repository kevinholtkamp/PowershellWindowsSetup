BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Install-Programs"{
    function script:Cleanup(){
        Remove-Item "$TestGroup\install\test.exe" -ErrorAction SilentlyContinue
        Remove-Item "$TestGroup\install\from-url.txt" -ErrorAction SilentlyContinue
        Remove-Item "$TestGroup\install\from-chocolatey.txt" -ErrorAction SilentlyContinue
        Remove-Item "$TestGroup\install\from-winget.txt" -ErrorAction SilentlyContinue
        Remove-Item "$TestGroup\install\chocolatey-repository.ini" -ErrorAction SilentlyContinue
    }
    BeforeAll{
        Cleanup
    }
    AfterEach{
        Cleanup
    }
    Context "Install from URL"{
        BeforeAll{
            Mock Start-Process {}
        }
        It "Normal installation"{
            Set-Content "$TestGroup\install\from-url.txt" "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.3.3/npp.8.3.3.Installer.x64.exe"

            Install-Programs -Group $TestGroup

            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {$FilePath -eq "$($Env:TEMP)\1.exe" -and $ArgumentList -eq "/S" -and $Wait -eq $true}
            "$($Env:TEMP)\1.exe" | Should -Not -Exist
        }
        It "Broken URL"{
            New-Item "$TestGroup\install\from-url.txt" -ItemType File
            Set-Content "$TestGroup\install\from-url.txt" "https://google.de/file.exe"

            {Install-Programs -Group $TestGroup} | Should -Throw

            "$($Env:TEMP)\1.exe" | Should -Not -Exist
        }
        It "Non executable file"{
            New-Item "$TestGroup\install\from-url.txt" -ItemType File
            Set-Content "$TestGroup\install\from-url.txt" "https://github.com/kevinholtkamp/PowershellWindowsSetup/blob/94ba53b8ff6964f338afc169225dcb1a6ced3619/README.md"

            Install-Programs -Group $TestGroup

            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {$FilePath -eq "$($Env:TEMP)\1.exe"}
            "$($Env:TEMP)\1.exe" | Should -Not -Exist
        }
    }
    Context "Install from exe"{
        It "Regular exe file"{
            $Date = Get-Date
            Copy-Item "C:\Windows\system32\notepad.exe" "$TestGroup\install\notepad.exe"
            New-Item "$TestGroup\install\de-DE\" -ItemType Directory -Force
            Copy-Item "C:\Windows\system32\de-DE\notepad.exe.mui" "$TestGroup\install\de-DE\notepad.exe.mui"

            Install-Programs -Group $TestGroup

#            Get-Process -name "notepad" | Where-Object -Property starttime -ge $Date | Should -Not -Be $null
            $Process = Get-Process -name "notepad" | Where-Object -Property starttime -ge $Date
            $Process | Should -Not -Be $null
            Stop-Process $Process -Force
            Wait-Process $Process
            $Process.HasExited | Should -Be $true

            Remove-Item "$TestGroup\install\notepad.exe" -Force
            Remove-Item "$TestGroup\install\de-DE\notepad.exe.mui" -Force
            Remove-Item "$TestGroup\install\de-DE" -Force
        }
        It "Fake exe file"{
            Mock Start-Process {}

            New-Item "$TestGroup\install\test.exe" -ItemType File

            Install-Programs -Group $TestGroup

#            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {$FilePath -like "*$TestGroup\install\test.exe" -and $ArgumentList -eq "/S" -and $Wait -eq $true}
            Should -Invoke Start-Process -Times 1 -Exactly #-ParameterFilter {$ArgumentList -eq "/S" -and $Wait -eq $true}

            Remove-Item "$TestGroup\install\test.exe"
        }
    }
    Context "Install choco"{
        It "Installing choco"{
            Mock Start-Job {0}
            Mock Stop-Job {}

            New-Item "$TestGroup\install\from-chocolatey.txt"

            Install-Programs -Group $TestGroup

            Should -Invoke Start-Job -Times 1 -Exactly
        }
        It "Installing from choco"{
            function script:choco(){}
            Mock choco {}

            New-Item "$TestGroup\install\from-chocolatey.txt"
            Set-Content "$TestGroup\install\from-chocolatey.txt" "testChocoPackage"

            Install-Programs -Group $TestGroup

            Should -Invoke choco -Times 3 -Exactly
        }
        It "Chocolatey repository"{
            function script:choco(){}
            Mock choco {}

            New-Item "$TestGroup\install\from-chocolatey.txt"
            New-Item "$TestGroup\install\chocolatey-repository.ini"
            Set-Content "$TestGroup\install\chocolatey-repository.ini" "[chocolatey]
source=https://community.chocolatey.org/api/v2/
priority=1"

            Install-Programs -Group $TestGroup

            Should -Invoke choco -Times 3 -Exactly
        }
    }
    Context "Winget"{
        It "Install winget"{
            Mock Start-Process {}
            Mock Wait-Process {}

            New-Item "$TestGroup\install\from-winget.txt"

            Install-Programs -Group $TestGroup

            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {$FilePath -eq "ms-appinstaller:?source=https://aka.ms/getwinget"}
        }
        It "Install from winget"{
            function script:winget(){}
            Mock winget {}

            New-Item "$TestGroup\install\from-winget.txt"
            Set-Content "$TestGroup\install\from-winget.txt" "wingetTestPackage"

            Install-Programs -Group $TestGroup

            Should -Invoke winget -Times 1 -Exactly
        }
    }
}