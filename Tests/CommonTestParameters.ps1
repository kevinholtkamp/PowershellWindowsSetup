Set-Variable -Name "TestGroup" -Value "Tests\testGroup" -Scope Script

Mock -CommandName Write-Host -MockWith {}
Mock -CommandName Write-Debug -MockWith {}
Mock -CommandName Write-Verbose -MockWith {}
Mock -CommandName Read-Host -MockWith {}
Set-Variable -Name "DebugPreference" -Value "silentlyContinue" -Scope Script
Set-Variable -Name "ErrorActionPreference" -Value "silentlyContinue" -Scope Script
Set-Variable -Name "VerbosePreference" -Value "silentlyContinue" -Scope Script
Set-Variable -Name "ProgressPreference" -Value "silentlyContinue" -Scope Script

. .\functions.ps1
. .\setup.ps1