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