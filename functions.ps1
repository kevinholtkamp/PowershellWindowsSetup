Function Test-Symlink($Path){
    if(Test-Path $Path){
        ((Get-Item $Path).Attributes.ToString() -match "ReparsePoint")
    }
    else{
        $False
    }
}
Function Get-SymlinkTarget($Path){
    if(Test-Symlink $Path){
        try{
            ((Get-Item $Path | Select-Object -ExpandProperty Target) -replace "^UNC\\", "\\")
        }
        catch{
            ""
        }
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
function Split-ToArrayLiteral($Array){
    "@($($Array | ForEach-Object {"'$_'"} | Join-StringCustom -Separator ','))"
}