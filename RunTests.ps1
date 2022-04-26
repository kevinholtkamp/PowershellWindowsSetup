$ProgressPreference = "silentlycontinue"

Write-Host "Installing Custom Repo" -ForegroundColor Green
#Install-PackageProvider -Name NuGet -Force -Confirm:$false
$Rep = @{
    Name = "CustomRepository"
    SourceLocation = "\\raspberrypi\Private\PowershellRepository\"
    PublishLocation = "\\raspberrypi\Private\PowershellRepository\"
    InstallationPolicy = "Trusted"
}
Register-PSRepository @Rep
if(!(Get-InstalledModule Pester -ErrorAction "silentlyContinue")){
    Write-Host "Installing Pester" -ForegroundColor Green
    Install-Module -Name Pester -MinimumVersion "5.0.0" -Force -SkipPublisherCheck -Confirm:$false -Repository "CustomRepository"
}

Write-Host "Invoking Pester" -ForegroundColor Green
Invoke-Pester ".\Tests\" -PassThru

Write-Host "Tests finnished" -ForegroundColor Green
Read-Host