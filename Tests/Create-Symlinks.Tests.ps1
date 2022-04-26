BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

Describe "Create-Symlinks"{
    BeforeAll{
        New-Item "TestDrive:\Original\Existing\Existing" -ItemType "directory" -Force
        New-Item "TestDrive:\Original\Existing\New" -ItemType "directory" -Force
        New-Item "TestDrive:\Links\Existing\Existing" -ItemType "directory" -Force
        New-Item "TestDrive:\Links\New\Existing" -ItemType "directory" -Force
        Set-Content "TestDrive:\Links\New\Existing\File.txt" "TestFileContentLinks" -Force
        Set-Content "TestDrive:\Links\Existing\Existing\File.txt" "TestFileContentLinks" -Force
        Set-Content "TestDrive:\Original\Existing\Existing\File.txt" "TestFileContentOriginal" -Force
        Set-Content "TestDrive:\Original\Existing\New\File.txt" "TestFileContentOriginal" -Force

        Create-Symlinks -Group $TestGroup
    }
    Context "Tests"{
        It "Nothing Exists"{
            Test-Symlink "TestDrive:\Original\New\New" | Should -Be $true
            "TestDrive:\Links\New\New" | Should -Exist
        }
        It "Existing Original folder"{
            Test-Symlink "TestDrive:\Original\Existing\New" | Should -Be $true
            "TestDrive:\Links\Existing\New" | Should -Exist
            "TestDrive:\Links\Existing\New\File.txt" | Should -FileContentMatch "TestFileContentOriginal"
            "TestDrive:\Original\Existing\New\File.txt" | Should -FileContentMatch "TestFileContentOriginal"
        }
        It "Existing LinkPath"{
            Test-Symlink "TestDrive:\Original\New\Existing" | Should -Be $true
            "TestDrive:\Links\New\Existing" | Should -Exist
            "TestDrive:\Links\New\Existing\File.txt" | Should -FileContentMatch "TestFileContentLinks"
            "TestDrive:\Original\New\Existing\File.txt" | Should -FileContentMatch "TestFileContentLinks"
        }
        It "Both existing"{
            Test-Symlink "TestDrive:\Original\Existing\Existing" | Should -Be $true
            "TestDrive:\Links\Existing\Existing" | Should -Exist
            "TestDrive:\Links\Existing\Existing\File.txt" | Should -FileContentMatch "TestFileContentOriginal"
            "TestDrive:\Original\Existing\Existing\File.txt" | Should -FileContentMatch "TestFileContentOriginal"
        }
    }
}