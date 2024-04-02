"PSWinRAR", "PSHelperTools" | ForEach-Object {
    if(!(Get-InstalledModule $_ -ErrorAction SilentlyContinue)){
        Install-Module $_ -Force -ErrorAction Stop
        Import-Module $_ -Force -ErrorAction Stop
    }
}

$Answer = PromptYesNo "Do you want to manually enter files to backup?"
if($Answer){
    $Files = Read-ArrayInput "Files, directories or wildcards"
}
else{
    Write-Host "Enter the configuration name: " -ForegroundColor Green -NoNewline
    $Configuration = Read-Host
    $Files = Get-Content "./$Configuration/backup.txt" | Where-Object {$_ -notlike ";*"}
}

$Files | Compress-WinRAR `
    -Archive "$(Get-Location)\Backup.rar" `
    -ArchiveFileStructure "Full" `
    -Preset "High" `
    -ErrorAction "Continue" `
    -RecoveryPercentage 5 `
    -Verbose