BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

Describe "Remove-Bloatware"{
    #ToDo make test non intrusive for host
    Context "Remove-Bloatware"{
        BeforeAll{
            Remove-Bloatware -Group $TestGroup
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