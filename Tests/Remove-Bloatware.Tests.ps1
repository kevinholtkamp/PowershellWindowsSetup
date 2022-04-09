BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

Describe "Remove-Bloatware"{
    Context "Remove-Bloatware"{
        BeforeAll{
            $DebugPreference = "continue"
            Remove-Bloatware -Group $TestGroup
            $DebugPreference = "silentlycontinue"
        }
        It "Removing bloatware *candy*"{
            Get-AppxPackage *candy* | Should -Be $null
        }
        It "Removing bloatware *king*"{
            Get-AppxPackage *king* | Should -Be $null
        }
        It "Removing bloatware *xing*"{
            Get-AppxPackage *xing* | Should -Be $null
        }
    }
}