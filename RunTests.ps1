$ProgressPreference = "silentlycontinue"

Write-Host "Installing NuGet" -ForegroundColor Green
Install-PackageProvider -Name NuGet -Force -Confirm:$false
if(!(Get-InstalledModule Pester -ErrorAction "silentlyContinue")){
    Write-Host "Installing Pester" -ForegroundColor Green
    Install-Module -Name Pester -MinimumVersion "5.0.0" -Force -SkipPublisherCheck -Confirm:$false
}
if(!(Get-InstalledModule PsIni -ErrorAction "silentlyContinue")){
    Write-Host "Installing PsIni" -ForegroundColor Green
    Install-Module -Name PsIni -Force -Confirm:$false
}
if(!(Get-InstalledModule Recycle -ErrorAction "silentlyContinue")){
    Write-Host "Installing Recycle" -ForegroundColor Green
    Install-Module -Name Recycle -Force -Confirm:$false
}

Write-Host "Invoking Pester" -ForegroundColor Green
Invoke-Pester ".\Tests\" -PassThru

Write-Host "Tests finnished" -ForegroundColor Green
Read-Host