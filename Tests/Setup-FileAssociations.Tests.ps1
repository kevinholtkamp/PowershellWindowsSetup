BeforeAll {
    . .\Tests\CommonTestParameters.ps1

    . .\functions.ps1
}

#Testing the helper function Create-Association since Setup-FileAssociations is just a wrapper and ini reader
Describe "Setup-FileAssociations"{
    Context "Setup-FileAssociations"{
        BeforeAll{
            $AssociationBefore = cmd.exe /c "assoc .csv"
            $AssociationBefore = $AssociationBefore.Split('=')[1]
        }
        AfterAll{
            Create-Association ".csv" $AssociationBefore
        }
        It "Setting Editor for .csv"{
#            Setup-FileAssociations -Group $TestGroup
            Create-Association ".csv" "C:\Windows\system32\notepad.exe"
            cmd.exe /c "assoc .csv" | Should -Be ".csv=C:\Windows\system32\notepad.exe"
        }
    }
}