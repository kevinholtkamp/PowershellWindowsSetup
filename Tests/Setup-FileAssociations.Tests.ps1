BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Setup-FileAssociations"{
    Context "Setup-FileAssociations"{
        BeforeAll{
            $AssociationBefore = cmd.exe /c "assoc .csv"
            if($AssociationBefore){
                $AssociationBefore = $AssociationBefore.Split('=')[1]
            }

            $AssociationBefore | Should -Not -Be "C:\Windows\system32\notepad.exe"

            Set-Content "$TestGroup\settings\associations.ini" '[associations]
.csv="C:\Windows\system32\notepad.exe"'
        }
        AfterAll{
            Create-Association ".csv" $AssociationBefore

            Remove-Item "$TestGroup\settings\associations.ini"
        }
        It "Setting Editor for .csv"{
            Setup-FileAssociations -Group $TestGroup
            cmd.exe /c "assoc .csv" | Should -Be ".csv=csvfile"
        }
    }
}