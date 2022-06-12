function Test-Configuration($Group = "default"){
    #Check registry file
    if(Test-Path "$Group\settings\registry.reg"){
        $Header = '(Windows Registry Editor Version 5\.00)'
        $Location = '(\[-?[\w \.\\]+\])'
        $Key = '(("?[\w \.]+"?=(\w*:\w*|"[^"]*"|-)))'
        $Comment = '(;.*)'
        $NewLine = '(\r?\n)'
        $Regex = "^$Header($NewLine+$Location($NewLine+$Key|$NewLine+$Comment)*)*$NewLine*$"
        if((Get-Content "$Group\settings\registry.reg") -match $Regex){
            Write-Host "Registry file matches correct syntax"
        }
        else{
            Write-Host "Registry file does not match correct syntax"
        }
    }
    else{
        Write-Host "No registry file in group"
    }
}