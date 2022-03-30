. .\functions.ps1


#ToDo - More Write-Host messages and change some into Write-Debug
#ToDo - Example GPO importfile
#ToDo - Taskbar import not working, possibly microsoft removed it
#ToDo - Split settings.ini

function Setup-FileAssociations($Associations){
    Write-Host "Setting up file associations"
    foreach($extension in $Associations.Keys){
        Write-Debug "Creating association $($Associations[$extension]) for file type $extension"
        Create-Association $extension  $Associations[$extension]
        Write-Debug "Done creating association $($Associations[$extension]) for file type $extension"
    }
    Write-Host "Done setting up file associations"
}

function Load-Registry($Group = "default"){
    if(Test-Path ".\$Group\settings\registry.reg"){
        Write-Host "Importing registry file"
        reg import ".\$Group\settings\registry.reg"
        Write-Host "Done importing registry file"
    }else{
        Write-Host "Cannot find registry file"
    }
}

function Create-Symlinks($linkPath = "X:\Links", $Links){
    #ToDo remove output of -WhatIf parameter
    Write-Host "Creating Symlinks"
    foreach($name in $Links.Keys){
        $path = $Links[$name]
        Write-Debug "Create-Symlink: $name | $($path):"
        Start-CustomTransaction
        try {
            if (Test-Path $path) {
                Write-Debug "Local folder exists"
                if (!(Test-Symlink "$path")) {
                    Write-Debug "Local folder is no Symlink yet"
                    if (!(Test-Path "$linkPath\$name")) {
                        Write-Debug "Does not exist in LinkPath"
                        New-ItemTransaction -Path "$linkPath\" -Name "$name" -ItemType "directory" -UseTransaction
                        Write-Debug "New folder created in LinkPath"
                    }
                    else {
                        Write-Debug "Exists in LinkPath"
                    }
                    Copy-ItemTransaction -Path "$path\*" -Destination "$linkPath\$name\" -Recurse -UseTransaction
                    Write-Debug "Copied to LinkPath sucessfully"
                    Remove-ItemSafelyTransaction -Path $path -Recurse -Force -UseTransaction
                    Write-Debug "Removed old folder"
                    New-ItemTransaction -Path $path -ItemType SymbolicLink -Value "$linkPath\$name" -UseTransaction
                    Write-Debug "SymLink created sucessfully"
                }
                else {
                    Write-Debug "Local folder is a SymLink already"
                    if (!(Test-Path "$linkPath\$name")) {
                        Write-Debug "But does not exist in LinkPath"
                        New-ItemTransaction -Path "$linkPath\" -Name "$name" -ItemType "directory" -UseTransaction
                        Write-Debug "New folder created in LinkPath"
                    }
                    else {
                        Write-Debug "Exists in LinkPath"
                    }
                    if ((Get-Item $path | Select-Object -ExpandProperty Target) -ne "$linkPath\$name") {
                        Write-Debug "Symlink exists, but has a wrong target"
                        Copy-ItemTransaction -Path "$path\*" -Destination "$linkPath\$name\" -Recurse -UseTransaction
                        Write-Debug "Everything copied from false target"
                        Remove-ItemSafelyTransaction -Path $path -UseTransaction
                        Write-Debug "Old symlink removed"
                        New-ItemTransaction -Path $path -ItemType SymbolicLink -Value "$linkPath\$name" -UseTransaction
                        Write-Debug "New Symlink created"
                    }
                    else {
                        Write-Debug "Symlink exists and has the correct target, no changes need to be made"
                    }
                }
            }
            else {
                Write-Debug "Local folder does not exist"
                if (!(Test-Path "$linkPath\$name")) {
                    Write-Debug "Does not exist in LinkPath"
                    New-ItemTransaction -Path "$linkPath\" -Name "$name" -ItemType "directory" -UseTransaction
                    Write-Debug "New folder created in LinkPath"
                }
                else {
                    Write-Debug "Exists in LinkPath"
                }
                New-ItemTransaction -Path $path -ItemType SymbolicLink -Value "$linkPath\$name" -Force -UseTransaction
                Write-Debug "Symlink created successfully"
            }
            Write-Debug "No errors occured, applying changes"
            Complete-CustomTransaction
        }catch{
            Write-Host "An error occured, rolling back changes"
            Undo-CustomTransaction
        }
    }
    Write-Host "Dont creating Symlinks"
}

function Set-OptionalFeatures($Features){
    Write-Host "Setting optional features"
    foreach($feature in $Features.Keys){
        Write-Debug "Feature $feature with targetstate $($Features[$feature])"
        if($Features[$feature] -eq "enable"){
            Get-WindowsOptionalFeature -FeatureName $feature -Online | Where-Object {$_.state -eq "Disabled"} | Enable-WindowsOptionalFeature -Online -NoRestart
        }else{
            Get-WindowsOptionalFeature -FeatureName $feature -Online | Where-Object {$_.state -eq "Enabled"} | Disable-WindowsOptionalFeature -Online -NoRestart
        }
        Write-Debug "Done with feature $feature with new state $((Get-WindowsOptionalFeature -FeatureName $feature -Online).State)"
    }
    Write-Host "Done setting optional features"
}

function Setup-Hosts($Group = "default"){
    Write-Host "Setting up hosts file"
    if(Test-Path ".\$Group\hosts\from-file.txt"){
        Write-Debug "Adding hosts from file"
        Add-Content -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Value (Get-Content -Path ".\$Group\hosts\from-file.txt")
        Write-Debug "Done adding hosts from file"
    }
    else{
        Write-Debug "No host from-file file found"
    }

    if(Test-Path ".\$Group\hosts\from-url.txt"){
        Write-Debug "Adding hosts from url"
        foreach($line in (Get-Content -Path ".\$Group\hosts\from-url.txt")){
            Write-Debug "Loading hosts from $line"
            Add-Content -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Value (Invoke-WebRequest -URI $line -UseBasicParsing).Content
            Write-Debug "Done loading hosts from $line"
        }
        Write-Debug "Done adding hosts from url"
    }
    else{
        Write-Debug "No host from-url file found"
    }
    Write-Host "Done setting up hosts file"
}

function Import-GPO($Group = "default"){
    if(Test-Path ".\$Group\settings\gpedit.txt"){
        Write-Host "Importing GPO from file"
        Import-GPO -BackupGPOName "Test-GPO" -Path ".\$Group\settings\gpedit.txt"
        Write-Host "Done importing GPO from file"
    }
    else{
        Write-Host "No gpedit file found"
    }
}

function Setup-Quickaccess($Group = "default"){
    if(Test-Path ".\$Group\quickaccess\folders.txt"){
        Write-Host "Setting up quickaccess"
        foreach ($folder in Get-Content ".\$Group\quickaccess\folders.txt") {
            Write-Debug "Adding $folder to quickaccess"
            (New-Object -com shell.application).Namespace($folder).Self.InvokeVerb("pintohome")
            Write-Debug "Done adding $folder to quickaccess"
        }
        Write-Host "Done setting up quickaccess"
    }
    else{
        Write-Host "No quickaccess file found"
    }
}

function Import-ScheduledTasks($Group = "default"){
    Write-Host "Importing scheduled tasks"
    foreach ($task in Get-Childitem ".\$Group\scheduledTasks\*.xml") {
        Write-Debug "Adding task $task"
        Register-ScheduledTask -Xml ".\$Group\ScheduledTasks\$task" -TaskName $task
        Write-Debug "Done adding task $task"
    }
    Write-Host "Done importing scheduled tasks"
}

function Install-Programs($Group = "default"){
    Write-Host "Installing programs"
    foreach($install in Get-Childitem ".\$Group\install\*.exe"){
        Write-Debug "Installing $install from file"
        & $install
        Write-Debug "Done installing $install from file"
    }

    if(Test-Path ".\$Group\install\from-url.txt"){
        Write-Debug "Installing from url"
        foreach ($url in Get-Content ".\$Group\install\from-url.txt"){
            Write-Debug "Installing $url from url"
            $index++
            (New-Object System.Net.WebClient).DownloadFile($url, "$($env:TEMP)\$index.exe")
            Start-Process "$($env:TEMP)\$index.exe" | Out-Null
            Write-Debug "Done installing $url from url"
        }
        Write-Debug "Done installing from url"
    }
    else{
        Write-Host "No install from-url file found"
    }

    if(Test-Path ".\$Group\install\from-chocolatey.txt") {
        Write-Debug "Installing chocolatey"
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
        choco feature enable -n allowGlobalConfirmation
        Write-Debug "Done installing chocolatey"
        if(Test-Path ".\$Group\install\chocolatey-repository.ini"){
            Write-Debug "Removing default repository and loading new repositories from file"
            choco source remove -n=chocolatey
            $sources = Get-IniContent ".\$Group\install\chocolatey-repository.ini"
            foreach($source in $sources.Keys) {
                $splatter = $sources[$source]
                choco source add --name $source @splatter
            }
            Write-Debug "Done removing default repository and loading new repositories from file"
        }
        Write-Debug "Installing from chocolatey"
        foreach ($i in (Get-Content ".\$Group\install\from-chocolatey.txt" | Where-Object { $_ -notlike ";*" })) {
            Write-Debug "Installing $i from chocolatey"
            choco install $i --limit-output --ignore-checksum
            choco pin add -n="$i"
            Write-Debug "Done installing $i from chocolatey"
        }
        Write-Debug "Done installing from chocolatey"
    }
    else{
        Write-Host "No install from-chocolatey file found"
    }

    if(Test-Path ".\$Group\install\from-winget.txt"){
        Write-Debug "Installing from winget"
        foreach ($i in (Get-Content ".\$Group\install\from-winget.txt" | Where-Object { $_ -notlike ";*" })){
            Write-Debug "Installing $i from winget"
            winget install $i
            Write-Debug "Done installing $i from winget"
        }
        Write-Debug "Done installing from winget"
    }
    else{
        Write-Host "No install from-winget file found"
    }
}

function Remove-Bloatware($Group = "default"){
    if(Test-Path ".\$Group\install\remove-bloatware.txt"){
        Write-Host "Removing bloatware"
        foreach($line in (Get-Content ".\$Group\install\remove-bloatware.txt")){
            Write-Debug "Removing $line"
            Get-AppxPackage $line | Remove-AppxPackage
            Write-Debug "Done removing $line"
        }
        Write-Host "Done removing bloatware"
    }
    else{
        Write-Host "No remove-bloatware file found"
    }
}

function Setup-Partitions($Group = "default"){
    Write-Host "Setting up partitions"
    if(Test-Path ".\$Group\settings\partitions.ini") {
        $partitions = Get-IniContent ".\$Group\settings\partitions.ini"
        #Find all driveletters that are wanted
        $unusable = @()
        foreach($drive in $partitions.Keys) {
            foreach ($partition in $partitions["$drive"].Keys) {
                $unusable += $partitions["$drive"]["$partition"]
            }
        }
        Write-Debug "Found all wanted driveletters: $unusable"
        #Find all drive letters that are currently in use
        $unusable += (Get-PSDrive).Root -match "^[A-Z]:\\"
        Write-Debug "Found all wanted and currently used driveletters: $unusable"
        #Find all free usable drive letters (Not currently used and not wanted)
        65..90|foreach-object{
            if (-not $unusable.Contains("$( [char]$_ ):\")) {
                $usable += [char]$_
            }
        }
        $usableIndex = 0
        Write-Debug "Found all freely usable drive letters (Not used  & not wanted): $usable"
        #Temporarily assign all partitions to one of those letters
        foreach($drive in $partitions.Keys) {
            foreach ($partition in $partitions["$drive"].Keys) {
                Write-Debug "Assigning partition $partition of drive $drive to temporary letter $( $usable[$usableIndex] )"
                Get-Disk | Where-Object SerialNumber -EQ "$drive" | Get-Partition | Where-Object PartitionNumber -EQ $partition | Set-Partition -NewDriveLetter $usable[$usableIndex]
                $usableIndex++
                Write-Debug "Done assigning partition $partition of drive $drive to temporary letter $( $usable[$usableIndex] )"
            }
        }
        Write-Debug "All partitions set to temporary driveletters"
        #Assign all partitions to their wanted letter
        foreach($drive in $partitions.Keys) {
            foreach ($partition in $partitions["$drive"].Keys) {
                Write-Debug "Assigning partition $partition of drive $drive to letter $( $partitions["$drive"]["$partition"] )"
                Get-Disk | Where-Object SerialNumber -EQ "$drive" | Get-Partition | Where-Object PartitionNumber -EQ $partition | Set-Partition -NewDriveLetter $partitions["$drive"]["$partition"]
                Write-Debug "Done assigning partition $partition of drive $drive to letter $( $partitions["$drive"]["$partition"] )"
            }
        }
        Write-Host "Done setting up partitions"
    }
    else{
        Write-Host "No partition file found"
    }
}

function Setup-Powershell($Group = "default"){
    Write-Host "Setting up Powershell"
    Update-Help
    if(Test-Path ".\$Group\install\powershell-packageprovider.txt"){
        Write-Debug "Installing packageproviders"
        foreach($pp in (Get-Content ".\$Group\install\powershell-packageprovider.txt")){
            Write-Debug "Installing packageprovider $pp"
            Install-PackageProvider -Name $pp -Force -Confirm:$false
            Write-Debug "Done installing packageprovider $pp"
        }
        Write-Debug "Done installing packageproviders"
    }
    else{
        Write-Host "No powershell-packageprovider file found"
    }

    if(Test-Path ".\$Group\install\powershell-module.txt"){
        Write-Debug "Installing modules"
        foreach($module in (Get-Content ".\$Group\install\powershell-module.txt")){
            Write-Debug "Installing module $module"
            Install-Module -Name $module -Force -Confirm:$false
            Write-Debug "Done installing module $module"
        }
        Write-Debug "Done installing modules"
    }
    else{
        Write-Host "No powershell-module file found"
    }
    Write-Host "Done setting up Powershell"
}

function Setup-Taskbar($Group = "default"){
    if(Test-Path ".\$Group\settings\taskbar.xml"){
        Write-Host "Setting up taskbar"
        Import-StartLayout -Layoutpath ".\$Group\settings\taskbar.xml" -Mountpath C:\
        Write-Host "Done setting up taskbar"
    }
    else{
        Write-Host "No Taskbar file found"
    }
}



function Start-Setup($Group = "default"){
    Start-Transcript "$home\Desktop\$(Get-Date -Format "yyyy_MM_dd")_setup.transcript"

    if(Test-Path ".\$Group\") {
        Write-Host "Creating Windows Checkpoint"
        Checkpoint-Computer -Description "Before Start-Setup at $( Get-Date )"
        Read-Host "Checkpoint created. Press enter to continue"

        Write-Host "Stopping Windows update service"
        net stop wuauserv | Write-Host
        Read-Host "Windows update service stopped. Press enter to continue"


        if(Test-Path ".\prepend_custom.ps1") {
            & ".\$Group\scripts\prepend_custom.ps1"
        }
        #ToDo check if there is an advantage of changing the order?
        $IniContent = Get-IniContent -filePath ".\$Group\settings\settings.ini"

        Setup-Powershell -Group $Group
        Setup-Partitions -Group $Group
        Load-Registry -Group $Group
        Set-OptionalFeatures -Features $IniContent["optionalfeatures"]
        Import-ScheduledTasks -Group $Group
        Import-GPO -Group $Group
        Create-Symlinks -Links $IniContent["links"]
        Setup-FileAssociations -Associations $IniContent["associations"]
        Setup-Hosts -Group $Group
        Setup-Taskbar -Group $Group
        Setup-Quickaccess -Group $Group
        Remove-Bloatware -Group $Group
        Install-Programs -Group $Group
        if(Test-Path ".\append_custom.ps1") {
            & ".\$Group\scripts\append_custom.ps1"
        }


        Write-Host "Creating Windows Checkpoint"
        Checkpoint-Computer -Description "After Start-Setup at $( Get-Date )"
        Read-Host "Checkpoint created. Press enter to continue"

        Write-Host "Starting Windows update service"
        net start wuauserv | Write-Host
        Write-Host "Windows update service started. Press enter to continue"
    }
    else{
        Write-Host "No group $Group found, terminating execution."
    }

    Stop-Transcript
}