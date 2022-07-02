BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-FileAssociations"{
    BeforeAll{
        New-Item "$TestConfiguration\settings" -ItemType Directory -Force -ErrorAction SilentlyContinue
    }
    AfterAll{
        Remove-Item "$TestConfiguration\settings" -Force -Recurse -ErrorAction SilentlyContinue
    }
    Context "Setup-FileAssociations"{
        BeforeAll{
            $AssociationBefore = Get-FTA ".abc"

            Set-Content "$TestConfiguration\settings\associations.ini" '[associations]'
            Add-Content "$TestConfiguration\settings\associations.ini" '.abc="C:\Windows\system32\notepad.exe"'
        }
        AfterAll{
            if($AssociationBefore){
                Register-FTA $AssociationBefore ".acb"
            }
            else{
                Remove-FTA "C:\Windows\system32\notepad.exe" ".abc"
            }

            Get-FTA ".abc" | Should -Be $AssociationBefore

            Remove-Item "$TestConfiguration\settings\associations.ini"
        }
        It "Setting Editor for .csv"{
            Setup-FileAssociations -Configuration $TestConfiguration -Verbose

            Get-FTA ".abc" | Should -Be "SFTA.notepad.abc"
        }
    }
}