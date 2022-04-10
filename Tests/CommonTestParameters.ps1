Set-Variable -Name "TestGroup" -Value "Tests\testGroup" -Scope Global

if(!(Get-InstalledModule PsIni -ErrorAction "silentlyContinue")){
    Install-Module -Name PsIni -Force -Confirm:$false
}
if(!(Get-InstalledModule Recycle -ErrorAction "silentlyContinue")){
    Install-Module -Name Recycle -Force -Confirm:$false
}

Mock -CommandName Write-Host -MockWith {}
Mock -CommandName Write-Debug -MockWith {}
Mock -CommandName Write-Verbose -MockWith {}
Mock -CommandName Read-Host -MockWith {}
Set-Variable -Name "DebugPreference" -Value "silentlyContinue" -Scope Global
Set-Variable -Name "ErrorActionPreference" -Value "silentlyContinue" -Scope Global
Set-Variable -Name "VerbosePreference" -Value "silentlyContinue" -Scope Global

#Mock -CommandName Write-Debug -MockWith {Write-Host $Prompt}
#Mock -CommandName Write-Verbose -MockWith {Write-Host $Prompt}
#Mock -CommandName Read-Host -MockWith {Write-Host $Prompt}
#Set-Variable -Name "DebugPreference" -Value "continue" -Scope Global
#Set-Variable -Name "ErrorActionPreference" -Value "continue" -Scope Global
#Set-Variable -Name "VerbosePreference" -Value "continue" -Scope Global