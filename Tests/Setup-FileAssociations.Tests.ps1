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
            $AssociationBefore = cmd.exe /c "assoc .csv" 2> $null
            if($AssociationBefore){
                $AssociationBefore = $AssociationBefore.Split('=')[1]
            }

            $AssociationBefore | Should -Not -Be "C:\Windows\system32\notepad.exe"

            Set-Content "$TestConfiguration\settings\associations.ini" '[associations]
.csv="C:\Windows\system32\notepad.exe"'
        }
        AfterAll{
            Create-Association ".csv" $AssociationBefore

            cmd.exe /c "assoc csvfile" 2> $null | Should -Be -NullOrEmpty

            Remove-Item "$TestConfiguration\settings\associations.ini"
        }
        It "Setting Editor for .csv"{
            Setup-FileAssociations -Configuration $TestConfiguration -Verbose

            cmd.exe /c "assoc .csv" 2> $null | Should -Be ".csv=csvfile"
            cmd.exe /c "assoc csvfile" 2> $null | Should -Be ".csv=csvfile"
        }
    }
}