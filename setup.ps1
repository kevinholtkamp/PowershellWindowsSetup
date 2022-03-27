. .\functions.ps1


#ToDo
# - Move ini file to be a parameter for functions which use it, call the function in Start-Setup (Then things like partitions can use their own ini file)
# - More Write-Host messages and change some into Write-Debug
# - Do file associations


function Create-Symlinks($linkPath = "X:\Links"){
    foreach($name in $IniContent["links"].Keys){
        $path = $IniContent["links"][$name]
        Write-Host "Start-Links: $name | $($path):"
        if(Test-Path $path){
            Write-Host "Local folder exists"
            if(!(Test-Symlink "$path")){
                Write-Host "Local folder is no Symlink yet"
                if(!(Test-Path "$linkPath\$name")){
                    Write-Host "Does not exist in LinkPath"
                    New-Item -Path "$linkPath\" -Name "$name" -ItemType "directory"
                    Write-Host "New folder created in LinkPath"
                }else{
                    Write-Host "Exists in LinkPath"
                }
                Copy-Item -Path "$path\*" -Destination "$linkPath\$name\" -Recurse
                Write-Host "Copied to LinkPath sucessfully"
                Remove-ItemSafely -Path $path -Recurse -Force
                Write-Host "Removed old folder"
                New-Item -Path $path -ItemType SymbolicLink -Value "$linkPath\$name"
                Write-Host "SymLink created sucessfully"
            }else{
                Write-Host "Local folder is a SymLink already"
                if(!(Test-Path "$linkPath\$name")){
                    Write-Host "But does not exist in LinkPath"
                    New-Item -Path "$linkPath\" -Name "$name" -ItemType "directory"
                    Write-Host "New folder created in LinkPath"
                }else{
                    Write-Host "Exists in LinkPath"
                }
                if((Get-Item $path | Select-Object -ExpandProperty Target) -ne "$linkPath\$name"){
                    Write-Host "Symlink exists, but has a wrong target"
                    Copy-Item -Path "$path\*" -Destination "$linkPath\$name\" -Recurse
                    Write-Host "Everything copied from false target"
                    Remove-ItemSafely -Path $path
                    Write-Host "Old symlink removed"
                    New-Item -Path $path -ItemType SymbolicLink -Value "$linkPath\$name"
                    Write-Host "New Symlink created"
                }else{
                    Write-Host "Symlink exists and has the correct target"
                }
            }
        }else{
            Write-Host "Local folder does not exist"
            if(!(Test-Path "$linkPath\$name")){
                Write-Host "Does not exist in LinkPath"
                New-Item -Path "$linkPath\" -Name "$name" -ItemType "directory"
                Write-Host "New folder created in LinkPath"
            }else{
                Write-Host "Exists in LinkPath"
            }
            New-Item -Path $path -ItemType SymbolicLink -Value "$linkPath\$name" -Force
            Write-Host "Symlink created successfully"
        }
    }
}

function Set-OptionalFeatures(){
    foreach($feature in $IniContent["optionalfeatures"].Keys){
        if($IniContent["optionalfeatures"][$feature] -eq "enable"){
            Get-WindowsOptionalFeature -FeatureName $feature -Online | Where-Object {$_.state -eq "Disabled"} | Enable-WindowsOptionalFeature -Online -NoRestart
        }else{
            Get-WindowsOptionalFeature -FeatureName $feature -Online | Where-Object {$_.state -eq "Enabled"} | Disable-WindowsOptionalFeature -Online -NoRestart
        }
    }
}

function Setup-Hosts(){
    if(Test-Path ".\hosts\from-file.txt"){
        Add-Content -Path "$( $Env:WinDir )\system32\Drivers\etc\hosts" -Value (Get-Content -Path ".\hosts\from-file.txt")
    }
    else{
        Write-Host "No host from-file file found"
    }

    if(Test-Path ".\hosts\from-url.txt"){
        foreach($line in (Get-Content -Path ".\hosts\from-url.txt")){
            Write-Host "Loading hosts from $line"
            Add-Content -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Value (Invoke-WebRequest -URI $line -UseBasicParsing).Content
            Write-Host "Done loading hosts from $line"
        }
    }
    else{
        Write-Host "No host from-url file found"
    }
}

function Import-GPO(){
    if(Test-Path ".\settings\gpedit.txt"){
        Import-GPO -BackupGPOName "Test-GPO" -Path ".\settings\gpedit.txt"
    }
    else{
        Write-Host "No gpedit file found"
    }
}

function Setup-Quickaccess(){
    if(Test-Path ".\quickaccess\folders.txt"){
        foreach ($folder in Get-Content ".\quickaccess\folders.txt") {
            (New-Object -com shell.application).Namespace($folder).Self.InvokeVerb("pintohome")
        }
    }
    else{
        Write-Host "No quickaccess file found"
    }
}

function Import-ScheduledTasks(){
    foreach ($task in Get-Childitem "./scheduledTasks/*.xml") {
        Register-ScheduledTask -Xml "./ScheduledTasks/$task" -TaskName $task
    }
}

function Install-Programs(){
    foreach($install in Get-Childitem ".\install\*.exe"){
        & $install
    }

    if(Test-Path ".\install\from-url.txt"){
        foreach ($url in Get-Content ".\install\from-url.txt"){
            $index++
            (New-Object System.Net.WebClient).DownloadFile($url, "$( $env:TEMP )/$index.exe")
            Start-Process "$( $env:TEMP )/$index.exe" | Out-Null
        }
    }
    else{
        Write-Host "No install from-url file found"
    }

    if(Test-Path ".\install\from-chocolatey.txt") {
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
        choco feature enable -n allowGlobalConfirmation
        foreach ($i in (Get-Content ".\install\from-chocolatey.txt" | Where-Object { $_ -notlike ";*" })) {
            choco install $i --limit-output --ignore-checksum
            choco pin add -n="$i"
        }
    }
    else{
        Write-Host "No install from-chocolatey file found"
    }

    if(Test-Path ".\install\from-winge.txt"){
        foreach ($i in (Get-Content ".\install\from-winget.txt" | Where-Object { $_ -notlike ";*" })){
            winget install $i
        }
    }
    else{
        Write-Host "No install from-winge file found"
    }
}

function Remove-Bloatware(){
    if(Test-Path ".\install\remove-bloatware.txt"){
        foreach($line in (Get-Content ".\install\remove-bloatware.txt")){
            Get-AppxPackage $line | Remove-AppxPackage
        }
    }
    else{
        Write-Host "No remove-bloatware file found"
    }
}

function Setup-Partitions(){
    #ToDo automate Partition setup
}

function Load-Ini($name = "setup.ini"){
    if(Test-Path ".\$name"){
        Set-Variable -Name "IniContent" -Value (Get-IniContent ".\$name") -Scope Global
        Write-Host "Ini geladen"
    }
    else{
        Write-Host "No $name file found"
    }
}

function Setup-Powershell(){
    Update-Help
    if(Test-Path ".\install\powershell-packageprovider.txt"){
        foreach($pp in (Get-Content ".\install\powershell-packageprovider.txt")){
            Install-PackageProvider -Name $pp -Force -Confirm:$false
        }
    }
    else{
        Write-Host "No powershell-packageprovider file found"
    }

    if(Test-Path ".\install\powershell-module.txt"){
        foreach($pp in (Get-Content ".\install\powershell-module.txt")){
            Install-Module -Name $pp -Force -Confirm:$false
        }
    }
    else{
        Write-Host "No powershell-module file found"
    }
}

function Setup-Taskbar(){
    if(Test-Path ".\settings\taskbar.xml"){
        Import-StartLayout -Layoutpath ".\settings\taskbar.xml" -Mountpath C:\
    }
    else{
        Write-Host "No Taskbar file found"
    }
}



function Start-Setup(){
    Start-Transcript "$home\Desktop\$(Get-Date -Format "yyyy_MM_dd")_setup.transcript"

    Write-Host "Creating Windows Checkpoint"
    Checkpoint-Computer -Description "Before Start-Setup at $(Get-Date)"
    Read-Host "Checkpoint created. Press enter to continue"

    Write-Host "Stopping Windows update service"
    net stop wuauserv | Write-Host
    Read-Host "Windows update service stopped. Press enter to continue"


    #ToDo check if there is an advantage of changing the order?
    Load-Ini
    Setup-Powershell
    Setup-Partitions
    Load-Registry
    Set-OptionalFeatures
    Import-ScheduledTasks
    Import-GPO
    Create-Symlinks
    Setup-Hosts
    Setup-Taskbar
    Setup-Quickaccess
    Remove-Bloatware
    Install-Programs


    Write-Host "Creating Windows Checkpoint"
    Checkpoint-Computer -Description "After Start-Setup at $(Get-Date)"
    Read-Host "Checkpoint created. Press enter to continue"

    Write-Host "Starting Windows update service"
    net start wuauserv | Write-Host
    Write-Host "Windows update service started. Press enter to continue"

    Stop-Transcript
}