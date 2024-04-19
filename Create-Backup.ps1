param(
    [Parameter(Position = 0)]
    [String] $Configuration = "default"
)


$config = Get-IniContent ".\$Configuration\backup\backup.ini"

$Compression
$Files = Get-Content ".\$Configuration\backup\backup_files.txt" | Where-Object {$_ -notlike ";*"}

if($config["winget"] -eq "true"){
    winget list | Add-Content ".\$Configuration\install\from-winget.txt"
}
if($config["choco"] -eq "true"){
    choco list --localonly | Add-Content ".\$Configuration\install\from-winget.txt"
}
switch ($Compression.ToLowercase()){
    "winrar" {
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
    "zip" {
        Compress-Archive `
        -Path $Files `
        -DestinationPath "$(Get-Location)\$Configuration\Backup.zip" `
        -CompressionLevel Optimal `
        -Verbose
    }
    Default{
    }
}