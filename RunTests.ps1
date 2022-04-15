Write-Host "Installing NuGet and Pester" -ForegroundColor Green
Install-PackageProvider -Name NuGet -Force -Confirm:$false
Install-Module -Name Pester -MinimumVersion "5.0.0" -Force -SkipPublisherCheck -Confirm:$false

Write-Host "Invoking Pester" -ForegroundColor Green
Invoke-Pester ".\Tests\" -PassThru -Output Detailed

Write-Host "Tests finnished" -ForegroundColor Green
Read-Host