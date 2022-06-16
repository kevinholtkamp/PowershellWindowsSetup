BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Custom scripts"{
    AfterAll{
        Remove-Item "$TestConfiguration\scripts\append_custom.ps1"
        Remove-Item "$TestConfiguration\scripts\prepend_custom.ps1"
    }
    It "Prepend-Script"{
        Set-Content "$TestConfiguration\scripts\prepend_custom.ps1" 'Set-Variable -Name "ExecutedPrepend" -Value $true -Scope Global'

        . "$TestConfiguration\scripts\prepend_custom.ps1"

        $ExecutedPrepend | Should -Be $true
    }
    It "Append-Script"{
        Set-Content "$TestConfiguration\scripts\append_custom.ps1" 'Set-Variable -Name "ExecutedAppend" -Value $true -Scope Global'

        . "$TestConfiguration\scripts\append_custom.ps1"

        $ExecutedAppend | Should -Be $true
    }
}