BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Create-Symlinks"{
    It "Empty parameter"{
        Mock New-Item {}
        Mock Copy-Item {}
        Mock Remove-ItemSafely {}

        Create-Symlinks -IniContent @{}

        Should -Invoke -CommandName New-Item -Exactly -Times 0
        Should -Invoke -CommandName Copy-Item -Exactly -Times 0
        Should -Invoke -CommandName Remove-ItemSafely -Exactly -Times 0
    }
    Context "Normal cases"{
        BeforeAll{
            New-Item "TestDrive:\Original\Existing\Existing" -ItemType "directory" -Force
            New-Item "TestDrive:\Original\Existing\New" -ItemType "directory" -Force
            New-Item "TestDrive:\Links\Existing\Existing" -ItemType "directory" -Force
            New-Item "TestDrive:\Links\New\Existing" -ItemType "directory" -Force
            Set-Content "TestDrive:\Original\Existing\Existing\File.txt" "TestFileContentOriginal" -Force
            Set-Content "TestDrive:\Original\Existing\New\File.txt" "TestFileContentOriginal" -Force
            Set-Content "TestDrive:\Links\New\Existing\File.txt" "TestFileContentLinks" -Force
            Set-Content "TestDrive:\Links\Existing\Existing\File.txt" "TestFileContentLinks" -Force

            Create-Symlinks -IniContent @{
                "TestDrive:\Links" = @{
                    "Existing\Existing" = "TestDrive:\Original\Existing\Existing"
                    "Existing\New" = "TestDrive:\Original\Existing\New"
                    "New\Existing" = "TestDrive:\Original\New\Existing"
                    "New\New" = "TestDrive:\Original\New\New"
                }
            } -ErrorAction "silentlycontinue"
        }
        It "Nothing Exists"{
            Test-Symlink "TestDrive:\Original\New\New" | Should -Be $true
            "TestDrive:\Links\New\New" | Should -Exist
        }
        It "Original folder exists"{
            Test-Symlink "TestDrive:\Original\Existing\New" | Should -Be $true
            "TestDrive:\Links\Existing\New" | Should -Exist
            "TestDrive:\Links\Existing\New\File.txt" | Should -FileContentMatch "TestFileContentOriginal"
            "TestDrive:\Original\Existing\New\File.txt" | Should -FileContentMatch "TestFileContentOriginal"
        }
        It "LinkPath exists"{
            Test-Symlink "TestDrive:\Original\New\Existing" | Should -Be $true
            "TestDrive:\Links\New\Existing" | Should -Exist
            "TestDrive:\Links\New\Existing\File.txt" | Should -FileContentMatch "TestFileContentLinks"
            "TestDrive:\Original\New\Existing\File.txt" | Should -FileContentMatch "TestFileContentLinks"
        }
        It "Both exist"{
            Test-Symlink "TestDrive:\Original\Existing\Existing" | Should -Be $true
            "TestDrive:\Links\Existing\Existing" | Should -Exist
            "TestDrive:\Links\Existing\Existing\File.txt" | Should -FileContentMatch "TestFileContentOriginal"
            "TestDrive:\Original\Existing\Existing\File.txt" | Should -FileContentMatch "TestFileContentOriginal"
        }
    }
    Context "Normal cases with -IniContent parameter"{
        BeforeAll{
            New-Item "TestDrive:\Original\Existing\Existing" -ItemType "directory" -Force
            New-Item "TestDrive:\Original\Existing\New" -ItemType "directory" -Force
            New-Item "TestDrive:\Links\Existing\Existing" -ItemType "directory" -Force
            New-Item "TestDrive:\Links\New\Existing" -ItemType "directory" -Force
            Set-Content "TestDrive:\Original\Existing\Existing\File.txt" "TestFileContentOriginal" -Force
            Set-Content "TestDrive:\Original\Existing\New\File.txt" "TestFileContentOriginal" -Force
            Set-Content "TestDrive:\Links\New\Existing\File.txt" "TestFileContentLinks" -Force
            Set-Content "TestDrive:\Links\Existing\Existing\File.txt" "TestFileContentLinks" -Force

            Create-Symlinks -IniContent @{
                "TestDrive:\Links" = @{
                    "Existing\Existing" =   "TestDrive:\Original\Existing\Existing"
                    "Existing\New"      =   "TestDrive:\Original\Existing\New"
                    "New\Existing"      =   "TestDrive:\Original\New\Existing"
                    "New\New"           =   "TestDrive:\Original\New\New"
                }
            } -ErrorAction "silentlycontinue"
        }
        It "Nothing Exists"{
            Test-Symlink "TestDrive:\Original\New\New" | Should -Be $true
            "TestDrive:\Links\New\New" | Should -Exist
        }
        It "Original folder exists"{
            Test-Symlink "TestDrive:\Original\Existing\New" | Should -Be $true
            "TestDrive:\Links\Existing\New" | Should -Exist
            "TestDrive:\Links\Existing\New\File.txt" | Should -FileContentMatch "TestFileContentOriginal"
            "TestDrive:\Original\Existing\New\File.txt" | Should -FileContentMatch "TestFileContentOriginal"
        }
        It "LinkPath exists"{
            Test-Symlink "TestDrive:\Original\New\Existing" | Should -Be $true
            "TestDrive:\Links\New\Existing" | Should -Exist
            "TestDrive:\Links\New\Existing\File.txt" | Should -FileContentMatch "TestFileContentLinks"
            "TestDrive:\Original\New\Existing\File.txt" | Should -FileContentMatch "TestFileContentLinks"
        }
        It "Both exist"{
            Test-Symlink "TestDrive:\Original\Existing\Existing" | Should -Be $true
            "TestDrive:\Links\Existing\Existing" | Should -Exist
            "TestDrive:\Links\Existing\Existing\File.txt" | Should -FileContentMatch "TestFileContentOriginal"
            "TestDrive:\Original\Existing\Existing\File.txt" | Should -FileContentMatch "TestFileContentOriginal"
        }
    }
    Context "Locked files"{
        BeforeEach{
            New-Item "TestDrive:\Original\Lock" -ItemType "directory" -Force
            New-Item "TestDrive:\Original\Lock\File.txt" -ItemType "file" -Force
            New-Item "TestDrive:\Target\Lock\File.txt" -ItemType "file" -Force
        }
        AfterEach{
            Remove-Item "TestDrive:\Original\Lock\File.txt"
            Remove-Item "TestDrive:\Original\Lock"
            Remove-Item "TestDrive:\Target\Lock\File.txt"

            $FileLock.close()
        }
        It "Locked file in original folder"{
            $FileLock = [System.IO.File]::Open("$((Get-PSDrive "TestDrive").Root)\Original\Lock\File.txt", "Open", "Read")

            {
                Create-Symlinks -IniContent @{
                    "TestDrive:\Links" = @{
                        "Lock" = "TestDrive:\Original\Lock"
                    }
                } -ErrorAction "stop"
            } | Should -Throw

            $FileLock.close()
        }
        It "Locked file in target folder"{
            $FileLock = [System.IO.File]::Open("$((Get-PSDrive "TestDrive").Root)\Target\Lock\File.txt", "Open", "Read")

            {
                Create-Symlinks -IniContent @{
                    "TestDrive:\Links" = @{
                        "Lock" = "TestDrive:\Original\Lock"
                    }
                } -ErrorAction "stop"
            } | Should -Not -Throw

            $FileLock.close()
        }
    }
    Context "Folder exist as file"{
        It "LinkPath is file"{
            New-Item "TestDrive:\Original\FileTest" -ItemType "directory" -Force
            New-Item "TestDrive:\Original\FileTest\File" -ItemType "file" -Force
            New-Item "TestDrive:\Links\FileTest" -ItemType "file" -Force

            {
                Create-Symlinks -IniContent @{
                    "TestDrive:\Links" = @{
                        "FileTest" = "TestDrive:\Original\FileTest"
                    }
                } -ErrorAction "stop"
            } | Should -Throw
            Test-Symlink "TestDrive:\Original\FileTest" | Should -Be $false
        }
        It "Original path is file"{
            New-Item "TestDrive:\Original\FileTest" -ItemType "file" -Force
            New-Item "TestDrive:\Links\FileTest" -ItemType "directory" -Force

            {
                Create-Symlinks -IniContent @{
                    "TestDrive:\Links" = @{
                        "FileTest" = "TestDrive:\Original\FileTest"
                    }
                } -ErrorAction "stop"
            } | Should -Throw
            Test-Symlink "TestDrive:\Original\FileTest" | Should -Be $false
        }
    }
}