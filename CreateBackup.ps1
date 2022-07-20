"PSWinRAR", "PSHelperTools" | % {
    if(!(Get-InstalledModule $_ -ErrorAction SilentlyContinue)){
        Install-Module $_ -Force -ErrorAction Stop
        Import-Module $_ -Force -ErrorAction Stop
    }
}


function PromptYesNo($Prompt){
    Write-Host "$Prompt (yes/no): " -ForegroundColor Blue -NoNewline
    while($true){
        $Answer = Read-Host
        $Answer = $Answer.ToLower()
        if($Answer -eq "yes" -or $Answer -eq "y"){
            return $true
        }
        elseif ($Answer -eq "no" -or $Answer -eq "n"){
            return $false
        }
        Write-Host "Please enter a valid answer: " -ForegroundColor Red -NoNewline
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

$Files | Compress-WinRAR -Archive "$(Get-Location)\$Configuration\$($_.Substring(0,1)).rar" `
                         -ArchiveFileStructure "Full" `
                         -Preset "High" `
                         -ErrorAction "Continue" `
                         -Verbose