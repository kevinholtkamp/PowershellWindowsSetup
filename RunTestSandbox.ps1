$ConfigFile = "$(Get-Location)\Tests\TestSandbox.wsb"
$SandboxExecutable = "C:\Windows\system32\WindowsSandbox.exe"

if(Test-Path $SandboxExecutable){
    #Add Host folder to sandbox config file
    ((Get-Content -Path $ConfigFile -Raw) -replace "<HostFolder>.*</HostFolder>", "<HostFolder>$(Get-Location)</HostFolder>").Trim() `
    | Out-File $ConfigFile

    #Launch Sandbox with configuration file
    Start-Process -WindowStyle ([System.Diagnostics.ProcessWindowStyle]::Maximized) `
    -FilePath $SandboxExecutable `
    -ArgumentList $ConfigFile
}
else{
    Write-Error "Sandbox not installed"
}