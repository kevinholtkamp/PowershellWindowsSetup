BeforeAll {
    . .\Tests\CommonTestParameters.ps1
}

Describe "Custom scripts"{
    It "Prepend-Script"{
        . "$TestGroup\scripts\prepend_custom.ps1"

        $ExecutedPrepend | Should -Be $true
    }
    It "Append-Script"{
        . "$TestGroup\scripts\append_custom.ps1"

        $ExecutedAppend | Should -Be $true
    }
}