. .\setup.ps1


Start-Setup -Group "test"


#Test hosts
    #From file
        if(Select-String -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Pattern "fritz.box"){
            Write-Host "Imported hosts from file successfully"
        }
        else{
            Write-Host "Failed to import hosts from file" -ForegroundColor red
        }
    #From url
        if(Select-String -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Pattern "Smart TV list"){
            Write-Host "Imported hosts from url successfully"
        }
        else{
            Write-Host "Failed to import hosts from url" -ForegroundColor red
        }
#Test install
    #Choco repository
        #ToDo is there a way to check for repository?
    #From chocolatey
        if(Test-Path "C:\Program Files (x86)\Steam"){
            Write-Host "Successfully installed Steam from chocolatey"
        }
        else{
            Write-Host "Failed to install Steam from chocolatey" -Foregroundcolor red
        }
        if(Test-Path "C:\Program Files\Git"){
            Write-Host "Successfully installed git from chocolatey"
        }
        else{
            Write-Host "Failed to install git from chocolatey" -Foregroundcolor red
        }
    #From url
        if(Test-Path "C:\Program Files\Chromium"){
            Write-Host "Successfully installed chromium from url"
        }
        else{
            Write-Host "Failed to install chromium from url" -Foregroundcolor red
        }
    #From winget
        if(Test-Path "C:\Program Files\PuTTY"){
            Write-Host "Successfully installed PuTTY from winget"
        }
        else{
            Write-Host "Failed to install PuTTY from winget" -Foregroundcolor red
        }
        if(Test-Path "C:\Program Files\WinRAR"){
            Write-Host "Successfully installed WinRAR from winget"
        }
        else{
            Write-Host "Failed to install WinRAR from winget" -Foregroundcolor red
        }
    #Powershell module
        if(Get-InstalledModule *NuGet*){
            Write-Host "Successfully installed package provider NuGet"
        }
        else{
            Write-Host "Failed to install package provider NuGet" -Foregroundcolor red
        }
    #Powershell package-provider
        if(Get-PackageProvider *NuGet*){
            Write-Host "Successfully installed package provider NuGet"
        }
        else{
            Write-Host "Failed to install package provider NuGet" -Foregroundcolor red
        }
    #Remove bloatware
        if(Get-PackageProvider *candy*){
            Write-Host "Successfully removed bloatware *candy*"
        }
        else{
            Write-Host "Failed to remove bloatware *candy*" -Foregroundcolor red
        }
        if(Get-PackageProvider *king*){
            Write-Host "Successfully removed bloatware *king*"
        }
        else{
            Write-Host "Failed to remove bloatware *candy*" -Foregroundcolor red
        }
        if(Get-PackageProvider *xing*){
            Write-Host "Successfully removed bloatware *xing*"
        }
        else{
            Write-Host "Failed to remove bloatware *candy*" -Foregroundcolor red
        }
#Test quickaccess
    #ToDo is there a way to check quickaccess items?
#Test scheduled Tasks
    if(Get-ScheduledTask *MicrosoftEdgeUpdateTaskMachineCore*){
        Write-Host "Successfully imported scheduled task"
    }
    else{
        Write-Host "Failed to import scheduled task" -Foregroundcolor red
    }
#Test scripts
    #Prepend
        if($ExecutedPrepend -eq $true){
            Write-Host "Executed prepend script"
        }
        else{
            Write-Host "Failed to execute prepend script" -ForegroundColor red
        }
    #Append
        if($ExecutedAppend -eq $true){
            Write-Host "Executed append script"
        }
        else{
            Write-Host "Failed to execute append script" -ForegroundColor red
        }
#Test settings
    #Registry
        if(Get-ItemPropertyValue -Path "HKCU:\Control Panel\Desktop" -Name "JPEGImportQuality"){
            Write-Host "Successfully import registry keys"
        }
        else{
            Write-Host "Failed to import registry keys" -Foregroundcolor red
        }
    #Settings
        #Optionalfeatures
            if(Get-WindowsOptionalFeature -FeatureName "DirectPlay" -Online | Where-Object {$_.state -eq "Enabled"}){
                Write-Host "Successfully enabled optional feature DirectPlay"
            }
            else{
                Write-Host "Failed to enable optional feature DirectPlay" -ForegroundColor red
            }
            if(Get-WindowsOptionalFeature -FeatureName "TelnetClient" -Online | Where-Object {$_.state -eq "Enabled"}){
                Write-Host "Successfully enabled optional feature TelnetClient"
            }
            else{
                Write-Host "Failed to enable optional feature TelnetClient" -ForegroundColor red
            }
        #Symlinks
            if(Test-Symlink "C:\Program Files (x86)\Steam\config"){
                Write-Host "Successfully created steam config symlink"
            }
            else{
                Write-Host "Failed to create steam config symlink" -ForegroundColor red
            }
        #File associations
            #ToDo is there a way to check file associations?



#ToDO GPEDIT + partitions