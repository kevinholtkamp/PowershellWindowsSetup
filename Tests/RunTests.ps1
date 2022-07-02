#Requires -RunAsAdministrator

Write-Host "Installing PackageProvider NuGet if not installed already" -ForegroundColor Yellow
Install-PackageProvider -Name NuGet -Confirm:$false -Force | Out-Null
$Repository = "CustomRepository"
if(!(Get-PsRepository "CustomRepository" -ErrorAction SilentlyContinue)){
    Write-Host "Installing Custom Repository" -ForegroundColor Yellow
    if($env:UserName -eq "WDAGUtilityAccount"){
        $Rep = @{
            Name = "CustomRepository"
            SourceLocation = "C:\Users\WDAGUtilityAccount\PowershellRepository"
            PublishLocation = "C:\Users\WDAGUtilityAccount\PowershellRepository"
            InstallationPolicy = "Trusted"
        }
    }else{
        $Rep = @{
            Name = "CustomRepository"
            SourceLocation = "\\raspberrypi\Public\PowershellRepository"
            PublishLocation = "\\raspberrypi\Public\PowershellRepository"
            InstallationPolicy = "Trusted"
        }
    }
    &{
        $ErrorActionPreference = "silentlycontinue"
        Register-PSRepository -ErrorAction "silentlycontinue" @Rep | Out-Null
    }
    if(Get-PsRepository "CustomRepository" -ErrorAction SilentlyContinue){
        $Repository = "CustomRepository"
    }
    else{
        Write-Host "Install failed, falling back to PSGallery" -ForegroundColor Red
        $Repository = "PSGallery"
        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    }
}
else{
    Write-Host "Custom Repository already installed" -ForegroundColor Green
    $Repository = "CustomRepository"
}
if(!(Get-InstalledModule Pester -ErrorAction "silentlyContinue")){
    Write-Host "Installing Pester" -ForegroundColor Yellow
    Install-Module -Name Pester -RequiredVersion "5.3.2" -SkipPublisherCheck -Repository $Repository
}
else{
    Write-Host "Pester already installed" -ForegroundColor Green
}
if(!(Get-InstalledModule PsIni -ErrorAction "silentlyContinue")){
    Write-Host "Installing PsIni" -ForegroundColor Yellow
    Install-Module -Name PsIni -Repository $Repository
}
else{
    Write-Host "PsIni already installed" -ForegroundColor Green
}
if(!(Get-InstalledModule Recycle -ErrorAction "silentlyContinue")){
    Write-Host "Installing Recycle" -ForegroundColor Yellow
    Install-Module -Name Recycle -Repository $Repository
}
else{
    Write-Host "Recycle already installed" -ForegroundColor Green
}
if(!(Get-InstalledModule PSHelperTools -ErrorAction "silentlyContinue")){
    Write-Host "Installing PSHelperTools" -ForegroundColor Yellow
    Install-Module -Name PSHelperTools -Repository $Repository
}
else{
    Write-Host "PSHelperTools already installed" -ForegroundColor Green
}

Write-Host "Invoking Pester" -ForegroundColor Green
&{
    Set-Variable -Name "DebugPreference" -Value "silentlyContinue" -Scope Script
    Set-Variable -Name "ErrorActionPreference" -Value "silentlyContinue" -Scope Script
    Set-Variable -Name "VerbosePreference" -Value "silentlyContinue" -Scope Script
    Set-Variable -Name "ProgressPreference" -Value "silentlyContinue" -Scope Script
    $script:PSDefaultParameterValues = @{
        "*:Confirm" = $false
        "*:ErrorAction" = "SilentlyContinue"
    #    "*:Force" = $true
    }
    $config = New-PesterConfiguration -HashTable @{
        Run = @{
            Path = "$(Get-Location)"
            PassThru = $true
        }
        CodeCoverage = @{
#            Enabled = $true
#            OutputPath = ".\Results\coverage.xml"
        }
        TestResult = @{
#            Enabled = $true
#            OutputPath = ".\Results\"
        }
        Should = @{
            ErrorAction = 'Continue'
        }
        Output = @{
            Verbosity = "Detailed"
            StackTraceVerbosity = "Filtered"
        }
        Debug = @{
            ShowFullErrors = $false
        }
    }
    $PesterResult = Invoke-Pester -Configuration $config
#    Remove-Item ".\Tests\testConfiguration" -Recurse -Force -ErrorAction "silentlycontinue" | Out-Null
}
