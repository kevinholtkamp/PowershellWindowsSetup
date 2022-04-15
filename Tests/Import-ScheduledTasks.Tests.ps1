BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

Describe "Import-ScheduledTasks"{
    Context "Import-ScheduledTasks"{
        BeforeAll{
            $DebugPreference = "continue"
            Import-ScheduledTasks -Group $TestGroup
            $DebugPreference = "silentlycontinue"
        }
        It "Import scheduled tasks"{
            Get-ScheduledTask *TestMicrosoftEdgeUpdateTaskMachineCore* | Should -Be $true
        }
    }
}