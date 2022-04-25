$ProgressPreference = "silentlycontinue"

Write-Host "Installing NuGet and Pester" -ForegroundColor Green
Install-PackageProvider -Name NuGet -Force -Confirm:$false
if(!(Get-InstalledModule Pester -ErrorAction "silentlyContinue")){
    Install-Module -Name Pester -MinimumVersion "5.0.0" -Force -SkipPublisherCheck -Confirm:$false
}
if(!(Get-InstalledModule PsIni -ErrorAction "silentlyContinue")){
    Install-Module -Name PsIni -Force -Confirm:$false
}
if(!(Get-InstalledModule Recycle -ErrorAction "silentlyContinue")){
    Install-Module -Name Recycle -Force -Confirm:$false
}

Write-Host "Invoking Pester" -ForegroundColor Green
Invoke-Pester ".\Tests\" -PassThru

Write-Host "Tests finnished" -ForegroundColor Green
Read-Host