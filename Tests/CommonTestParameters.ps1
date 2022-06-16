Set-Variable -Name "TestConfiguration" -Value "Tests\testConfiguration" -Scope Script

Mock -CommandName Write-Host -MockWith {}
Mock -CommandName Write-Debug -MockWith {}
Mock -CommandName Write-Verbose -MockWith {}
Mock -CommandName Read-Host -MockWith {Write-Host $Prompt}

. .\functions.ps1
. .\setup.ps1