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
Function Join-StringCustom{
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String[]]
        $Strings,
        [String]
        $Separator
    )
    Begin{
        $Array = [System.Collections.ArrayList]@()
    }
    Process{
        $Array.Add($Strings[0]) | Out-Null
    }
    End{
        $Return = ""
        for($i = 0; $i -lt $Array.Count - 1; $i = $i + 1){
            $Return = -join($Return, $Array[$i], $Separator)
        }
        $Return = -join($Return, $Array[$Array.Count - 1])
        $Return
    }
}