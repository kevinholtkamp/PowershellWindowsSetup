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
#Which Verb? Format? Optimize? Convert? Resolve? Unify is unapproved but fitting
Function Format-Path(){
    [Cmdletbinding()]
    param($Path)

    Write-Verbose "Format-Path: $Path"
    if($Path.StartsWith(".")){
        #Get Absolute path if path starts with "."
        $Path = Resolve-Path -Path $Path
        Write-Verbose "Resolved Path: $Path"
    }
    if($Path -match "^.*::(.*)"){
        $Path = $Path -replace "^.*::(.*)", '$1'
        Write-Verbose "Replaced Powershell providers: $Path"
    }
    $Path = $Path -replace "/"                      , "\" `
                  -replace "^\\\\\.\\"              , "" `
                  -replace "^\\\\\?\\"              , "" `
                  -replace "^UNC\\"                 , "\\"
    Write-Verbose "Replaced UNC conventions: $Path"

    if($Path -match "^\\\\([A-Za-z]+)(@SSL)?"){
        $Path = $Path -replace "^\\\\([A-Za-z]+)(@SSL)?", "\\$((Resolve-DnsName $matches[1] -Type "A").IPAddress)"
        Write-Verbose "Resolve name into IP: $Path"
    }

    return $Path.TrimEnd("\")
}
Function Resolve-Symlink(){
    [Cmdletbinding()]
    param($Path)

    Write-Verbose "Resolve-Symlink: $Path"
    $Path = Format-Path $Path
    Write-Verbose "Formatted: $Path"
    $Current = $Path
    while($Current){
        Write-Verbose "Current step: $Current"
        if(Test-Symlink $Current){
            $Target = Get-SymlinkTarget $Current
            Write-Verbose "Step is Symlink, replacing with target: $Target"
            $Path = $Path -replace "^$([System.Text.RegularExpressions.Regex]::Escape($Current))", "$Target"
            $Current = $Target
        }
        else{
            $Current = Split-Path -Path $Current -Parent -ErrorAction Stop
        }
    }
    Write-Verbose "Resolved Symlink: $Path"
    return Format-Path $Path
}
Function Compare-Paths(){
    [Cmdletbinding()]
    param([String]$First, [String]$Second)

    Write-Verbose "Comparing-Paths: '$First' to '$Second'"
    return (Resolve-Symlink $First -ErrorAction Stop) -eq (Resolve-Symlink $Second -ErrorAction Stop)
}