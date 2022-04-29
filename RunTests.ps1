$ProgressPreference = "silentlycontinue"

if(!(Get-PackageProvider "NuGet")){
    Write-Host "Installing PackageProvider NuGet" -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet
}
else{
    Write-Host "NuGet already installed" -ForegroundColor Green
}
$Repository = "CustomRepository"
if(!(Get-PsRepository "CustomRepository")){
    Write-Host "Installing Custom Repo" -ForegroundColor Yellow
    $Rep = @{
        Name = "CustomRepository"
        SourceLocation = "\\raspberrypi\Private\PowershellRepository\"
        PublishLocation = "\\raspberrypi\Private\PowershellRepository\"
        InstallationPolicy = "Trusted"
    }
    Register-PSRepository @Rep -ErrorAction stop
    if(Get-PsRepository "CustomRepository"){
        $Repository = "CustomRepository"
    }
    else{
        Write-Host "Install failed, falling back to PSGallery" -ForegroundColor Red
        $Repository = "PSGallery"
    }
}
else{
    Write-Host "Custom Repository already installed" -ForegroundColor Green
    $Repository = "CustomRepository"
}
if(!(Get-InstalledModule Pester -ErrorAction "silentlyContinue")){
    Write-Host "Installing Pester" -ForegroundColor Yellow
    Install-Module -Name Pester -RequiredVersion "5.3.2" -SkipPublisherCheck -Repository $Repository
}
else{
    Write-Host "Pester already installed" -ForegroundColor Green
}
if(!(Get-InstalledModule PsIni -ErrorAction "silentlyContinue")){
    Write-Host "Installing PsIni" -ForegroundColor Yellow
    Install-Module -Name PsIni -Repository $Repository
}
else{
    Write-Host "PsIni already installed" -ForegroundColor Green
}
if(!(Get-InstalledModule Recycle -ErrorAction "silentlyContinue")){
    Write-Host "Installing Recycle" -ForegroundColor Yellow
    Install-Module -Name Recycle -Repository $Repository
}
else{
    Write-Host "Recycle already installed" -ForegroundColor Green
}

Write-Host "Invoking Pester" -ForegroundColor Green
Invoke-Pester ".\Tests\" -PassThru

Write-Host "Tests finnished" -ForegroundColor Green
Read-Host