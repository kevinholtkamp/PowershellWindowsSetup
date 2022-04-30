BeforeAll {

    . .\setup.ps1

    . .\Tests\CommonTestParameters.ps1
}

#Testing the .reg file instead of the Load-Registry function
#Since the function uses "reg import" there is no need to test the actual function
Describe "Load-Registry"{
    BeforeAll{
        $Header = '(Windows Registry Editor Version 5\.00)'
        $Location = '(\[-?[\w \.\\]+\])'
        $Key = '(("?[\w \.]+"?=(\w*:\w*|"[^"]*"|-)))'
        $Comment = '(;.*)'
        $NewLine = '(\r?\n)'
        $Regex = "^$Header($NewLine+$Location($NewLine+$Key|$NewLine+$Comment)*)*$NewLine*$"
    }
    Context "Correct files"{
        It "Default test file"{
            "$TestGroup\settings\registry.reg" | Should -FileContentMatchMultiline $Regex
        }
    }
    Context "Files with errors"{
        It "Broken header"{
            "$TestGroup\settings\registry_brokenHeader.reg" | Should -Not -FileContentMatchMultiline $Regex
        }
        It "Broken Location"{
            "$TestGroup\settings\registry_brokenLocation.reg" | Should -Not -FileContentMatchMultiline $Regex
        }
        It "Broken Key"{
            "$TestGroup\settings\registry_brokenKey.reg" | Should -Not -FileContentMatchMultiline $Regex
        }
        It "Broken Value"{
            "$TestGroup\settings\registry_brokenValue.reg" | Should -Not -FileContentMatchMultiline $Regex
        }
    }
}