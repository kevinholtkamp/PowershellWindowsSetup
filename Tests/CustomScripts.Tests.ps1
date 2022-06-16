BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Custom scripts"{
    AfterAll{
        Remove-Item "$TestGroup\scripts\append_custom.ps1"
        Remove-Item "$TestGroup\scripts\prepend_custom.ps1"
    }
    It "Prepend-Script"{
        Set-Content "$TestGroup\scripts\prepend_custom.ps1" 'Set-Variable -Name "ExecutedPrepend" -Value $true -Scope Global'

        . "$TestGroup\scripts\prepend_custom.ps1"

        $ExecutedPrepend | Should -Be $true
    }
    It "Append-Script"{
        Set-Content "$TestGroup\scripts\append_custom.ps1" 'Set-Variable -Name "ExecutedAppend" -Value $true -Scope Global'

        . "$TestGroup\scripts\append_custom.ps1"

        $ExecutedAppend | Should -Be $true
    }
}