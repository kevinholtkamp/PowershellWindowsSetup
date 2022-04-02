Set-ExecutionPolicy RemoteSigned
Install-PackageProvider -Name NuGet -Force -Confirm:$false
Install-Module -Name Pester -MinimumVersion "5.0.0" -Force -SkipPublisherCheck -Confirm:$false


Invoke-Pester ".\Tests\"