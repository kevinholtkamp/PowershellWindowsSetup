param(
    [Parameter(Position = 0)]
    [String] $Configuration = "default",

    [Parameter(Position = 1)]
    [ValidateSet("WinRAR", "Zip")]
    [String] $Compression = "WinRAR"
)

"PSHelperTools" | ForEach-Object {
    if(!(Get-InstalledModule $_ -ErrorAction SilentlyContinue)){
        Install-Module $_ -Force -ErrorAction Stop
        Import-Module $_ -Force -ErrorAction Stop
    }
}

if(PromptYesNo "Do you want to manually enter files to backup?"){
    $Files = Read-ArrayInput "Files, directories or wildcards"
}
else{
    if(PromptYesNo "Do you want to use recommended settings instead of a configuration?"){
        $Files = @(
            "C:\Users\$($Env:UserName)\AppData\Roaming",
            "C:\Users\$($Env:UserName)\Desktop",
            "C:\Users\$($Env:UserName)\Documents",
            "C:\Users\$($Env:UserName)\Music",
            "C:\Users\$($Env:UserName)\Pictures",
            "C:\Users\$($Env:UserName)\Videos",
            "C:\Program Files (x86)",
            "C:\Program Files",
            "C:\ProgramData"
        )
    }
    else{
        Write-Host "Enter the configuration name: " -ForegroundColor Green -NoNewline
        $Configuration = Read-Host
        $Files = Get-Content "./$Configuration/backup.txt" | Where-Object {$_ -notlike ";*"}
    }
}

if($Compression -eq "WinRAR"){
    if(!(Get-InstalledModule "PSWinRAR" -SilentlyContinue)){
        Install-Module "PSWinRAR" -Force -ErrorAction Stop
        Import-Module "PSWinRAR" -Force -ErrorAction Stop
    }
    $Files | Compress-WinRAR `
        -Archive "$(Get-Location)\Backup.rar" `
        -ArchiveFileStructure "Full" `
        -Preset "High" `
        -ErrorAction "Continue" `
        -RecoveryPercentage 5 `
        -Verbose
}
else{
    Compress-Archive `
        -Path $Files `
        -DestinationPath "$(Get-Location)\$Configuration\Backup.zip" `
        -CompressionLevel Optimal `
        -Verbose
}
