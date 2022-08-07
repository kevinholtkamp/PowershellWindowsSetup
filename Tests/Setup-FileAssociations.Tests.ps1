BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-FileAssociations"{
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
    Context "Configuration parameter"{
        It "Setting Editor for .csv"{
            Set-Content "$TestConfiguration\settings\associations.ini" '[associations]'
            Add-Content "$TestConfiguration\settings\associations.ini" '.abc="C:\Windows\system32\notepad.exe"'

            Setup-FileAssociations -Configuration $TestConfiguration

            Get-FTA ".abc" | Should -Be "SFTA.notepad.abc"
        }
    }
    Context "IniContent parameter"{
        It "Setting Editor for .csv"{
            Setup-FileAssociations -IniContent @{associations = @{".abc" = "C:\Windows\system32\notepad.exe"}}

            Get-FTA ".abc" | Should -Be "SFTA.notepad.abc"
        }
    }
}