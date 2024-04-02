$ConfigFile = "$(Get-Location)\Tests\TestSandbox.wsb"
$SandboxExecutable = "C:\Windows\system32\WindowsSandbox.exe"

if(Test-Path $SandboxExecutable){
    #Launch Sandbox with configuration file
    Start-Process  `
        -WindowStyle ([System.Diagnostics.ProcessWindowStyle]::Maximized) `
        -FilePath $SandboxExecutable `
        -ArgumentList $ConfigFile `
}
else{
    Write-Error "Sandbox not enabled"
}