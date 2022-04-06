Function Test-Symlink($Path){
    if(Test-Path $Path){
        ((Get-Item $Path).Attributes.ToString() -match "ReparsePoint")
    }
    else{
        $False
    }
}
Function Get-SymlinkTarget($Path){
    if(Test-Path $Path){
        ((Get-Item $Path | Select-Object -ExpandProperty Target) -replace "^UNC\\","\\")
    }
    else{
        ""
    }
}
#Source: https://stackoverflow.com/a/59048942
Function Create-Association($Extension, $Executable){
    $Name = cmd /c "assoc $Extension 2>NUL"
    if($Name){
    # Association already exists: override it
        $Name = $Name.Split('=')[1]
    }
    else{
    # Name doesn't exist: create it
        $Name = "$($Extension.Replace('.', ''))file" # ".log.1" becomes "log1file"
        cmd /c 'assoc $ext=$name'
    }
    cmd /c "ftype $Name=`"$Executable`" `"%1`""
}

function New-ItemTransaction([string]$Path, [string]$Name, [string]$ItemType, [switch]$Force){
    New-Item -Path $Path -Name $Name -ItemType $ItemType -ErrorAction stop -WhatIf -Force:$Force | Out-Null
    $ScriptBlock = {New-Item -Path $Path -Name $Name -ItemType $ItemType -ErrorAction stop -Force:$Force}
    $LocalTransactionArray = Get-Variable -Name "TransactionArray" -Scope Global -ValueOnly
    $LocalTransactionArray += $ScriptBlock
    Set-Variable -Name "TransactionArray" -Scope Global -Value $LocalTransactionArray
}
function Copy-ItemTransaction([string]$Path, [string]$Destination, [switch]$Recurse, [switch]$Force){
    Copy-Item -Path $Path -Destination $Destination -Recurse:$Recurse -ErrorAction stop -WhatIf -Force:$Force | Out-Null
    $ScriptBlock = {Copy-Item -Path $Path -Destination $Destination -Recurse:$Recurse -ErrorAction stop -Force:$Force}
    $LocalTransactionArray = Get-Variable -Name "TransactionArray" -Scope Global -ValueOnly
    $LocalTransactionArray += $ScriptBlock
    Set-Variable -Name "TransactionArray" -Scope Global -Value $LocalTransactionArray
}
function Remove-ItemSafelyTransaction([string]$Path, [switch]$Recurse, [switch]$Force){
    Remove-ItemSafely -Path $Path -Recurse:$Recurse -Force:$Force -ErrorAction stop -WhatIf | Out-Null
    $ScriptBlock = {Remove-ItemSafely -Path $Path -Recurse:$Recurse -Force:$Force -ErrorAction stop}
    $LocalTransactionArray = Get-Variable -Name "TransactionArray" -Scope Global -ValueOnly
    $LocalTransactionArray += $ScriptBlock
    Set-Variable -Name "TransactionArray" -Scope Global -Value $LocalTransactionArray
}
function Start-CustomTransaction(){
    Set-Variable -Name "TransactionArray" -Scope Global -Value @()
}
function Complete-CustomTransaction(){
    $LocalTransactionArray = Get-Variable -Name "TransactionArray" -Scope Global -ValueOnly
    foreach($entry in $LocalTransactionArray){
        & $entry
    }
    Set-Variable -Name "TransactionArray" -Scope Global -Value @()
}
function Undo-CustomTransaction(){
    Set-Variable -Name "TransactionArray" -Scope Global -Value @()
}