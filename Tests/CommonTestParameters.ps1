if(!(Get-InstalledModule PsIni -ErrorAction "silentlyContinue")){
    Write-Host "Installing PsIni" -ForegroundColor Green
    Install-Module -Name PsIni -Force -Confirm:$false -Repository "CustomRepository"
}
if(!(Get-InstalledModule Recycle -ErrorAction "silentlyContinue")){
    Write-Host "Installing Recycle" -ForegroundColor Green
    Install-Module -Name Recycle -Force -Confirm:$false -Repository "CustomRepository"
}


Set-Variable -Name "TestGroup" -Value "Tests\testGroup" -Scope Global

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