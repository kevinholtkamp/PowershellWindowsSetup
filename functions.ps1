Function Test-Symlink($Path){
    ((Get-Item $Path).Attributes.ToString() -match "ReparsePoint")
}
function Get-IniContent ($filePath)
{
    $ini = @{}
    switch -regex -file $FilePath
    {
        "^\[(.+)\]" # Section
        {
            $section = $matches[1]
            $ini[$section] = @{}
        }
        "^(;.*)$" # Comment
        {
        }
        "(.+?)\s*=(.*)" # Key
        {
            $ini[$section][$matches[1]] = $matches[2]
        }
    }
    return $ini
}
#Source: https://stackoverflow.com/a/59048942
Function Create-Association($ext, $exe) {
    $name = cmd /c "assoc $ext 2>NUL"
    if ($name) { # Association already exists: override it
        $name = $name.Split('=')[1]
    } else { # Name doesn't exist: create it
        $name = "$($ext.Replace('.',''))file" # ".log.1" becomes "log1file"
        cmd /c 'assoc $ext=$name'
    }
    cmd /c "ftype $name=`"$exe`" `"%1`""
}