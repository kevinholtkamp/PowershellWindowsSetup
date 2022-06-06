Set-Variable -Name "TestGroup" -Value "Tests\testGroup" -Scope Global

Mock -CommandName Write-Host -MockWith {}
Mock -CommandName Write-Debug -MockWith {}
Mock -CommandName Write-Verbose -MockWith {}
Mock -CommandName Read-Host -MockWith {}
Set-Variable -Name "DebugPreference" -Value "silentlyContinue" -Scope Global
Set-Variable -Name "ErrorActionPreference" -Value "silentlyContinue" -Scope Global
Set-Variable -Name "VerbosePreference" -Value "silentlyContinue" -Scope Global
Set-Variable -Name "ProgressPreference" -Value "silentlyContinue" -Scope Global