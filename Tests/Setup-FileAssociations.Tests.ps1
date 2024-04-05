BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-FileAssociations"{
    It "Empty parameter"{
        Mock Register-FTA {}

        Setup-FileAssociations -IniContent @{}

        Should -Invoke -CommandName Register-FTA -Exactly -Times 0
    }
    BeforeAll{
        New-Item "$TestConfiguration\settings" -ItemType Directory -Force -ErrorAction SilentlyContinue

        $AssociationBefore = Get-FTA ".abc"
    }
    AfterAll{
        Remove-Item "$TestConfiguration\settings" -Force -Recurse -ErrorAction SilentlyContinue

        if($AssociationBefore){
            Register-FTA $AssociationBefore ".acb"
        }
        else{
            Remove-FTA "C:\Windows\system32\notepad.exe" ".abc"
        }

        Get-FTA ".abc" | Should -Be $AssociationBefore

        Remove-Item "$TestConfiguration\settings\associations.ini" -Force -ErrorAction "SilentlyContinue"
    }
    It "Setting Editor for .csv"{
        Setup-FileAssociations -IniContent @{
            "associations" = @{
                ".abc" = "C:\Windows\system32\notepad.exe"
            }
        }

        Get-FTA ".abc" | Should -Be "SFTA.notepad.abc"
    }
}