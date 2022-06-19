. .\functions.ps1


function Setup-FileAssociations($Configuration = "default"){
    Write-Host "Setting up file associations"
    $Associations = Get-IniContent -FilePath ".\$Configuration\settings\associations.ini" -IgnoreComments
    foreach($Extension in $Associations.Keys){
        Write-Verbose "Creating association $($Associations[$Extension]) for file type $Extension"
        Create-Association $Extension $Associations[$Extension]
        Write-Verbose "Done creating association $($Associations[$Extension]) for file type $Extension"
    }
    Write-Host "Done setting up file associations"
}

function Load-Registry($Configuration = "default"){
    if(Test-Path ".\$Configuration\settings\registry.reg"){
        Write-Host "Importing registry file"
        reg import ".\$Configuration\settings\registry.reg"
        Write-Host "Done importing registry file"
    }
    else{
        Write-Host "Cannot find registry file"
    }
}

function Create-Symlinks($Configuration = "default"){
    Write-Host "Creating Symlinks"
    if(Test-path ".\$Configuration\settings\symlinks.ini"){
        $IniContent = Get-IniContent -FilePath ".\$Configuration\settings\symlinks.ini" -IgnoreComments
        foreach($LinkPath in $IniContent.Keys){
            Write-Verbose "Creating Symlinks for LinkPath $LinkPath"
            if(!(Test-Path $LinkPath)){
                New-Item $LinkPath -ItemType Directory -Force
            }
            $Links = $IniContent[$LinkPath]
            foreach($Name in $Links.Keys){
                $Path = $Links[$Name]
                Write-Verbose "Create-Symlink: $Name | $($Path):"
                try{
                    if(Test-Path $Path){
                        Write-Verbose "Local folder exists"
                        if(!(Test-Symlink "$Path")){
                            Write-Verbose "Local folder is no Symlink yet"
                            if(!(Test-Path "$LinkPath\$Name")){
                                Write-Verbose "Does not exist in LinkPath"
                                New-Item -Path "$LinkPath\" -Name "$Name" -ItemType "directory" -Force
                                Write-Verbose "New folder created in LinkPath"
                            }
                            else{
                                Write-Verbose "Exists in LinkPath"
                            }
                            Copy-Item -Path "$Path\*" -Destination "$LinkPath\$Name\" -Recurse
                            Write-Verbose "Copied to LinkPath sucessfully"
                            Remove-ItemSafely -Path $Path -Recurse -Force
                            Write-Verbose "Removed old folder"
                            New-Item -Path $Path -ItemType SymbolicLink -Value "$LinkPath\$Name" -Force
                            Write-Verbose "SymLink created sucessfully"
                        }
                        else{
                            Write-Verbose "Local folder is a SymLink already"
                            if(!(Test-Path "$LinkPath\$Name")){
                                Write-Verbose "But does not exist in LinkPath"
                                New-Item -Path "$LinkPath\" -Name "$Name" -ItemType "directory" -Force
                                Write-Verbose "New folder created in LinkPath"
                            }
                            else{
                                Write-Verbose "Exists in LinkPath"
                            }
                            if((Get-SymlinkTarget $Path) -ne "$LinkPath\$Name"){
                                Write-Verbose "Symlink exists, but has a wrong target"
                                Write-Verbose "Target: $LinkPath\$Name"
                                Write-Verbose "Wanted Target: $(Get-SymlinkTarget $Path)"
                                Copy-Item -Path "$Path\*" -Destination "$LinkPath\$Name\" -Recurse
                                Write-Verbose "Everything copied from false target"
                                Remove-ItemSafely -Path $Path
                                Write-Verbose "Old symlink removed"
                                New-Item -Path $Path -ItemType SymbolicLink -Value "$LinkPath\$Name" -Force
                                Write-Verbose "New Symlink created"
                            }
                            else{
                                Write-Verbose "Symlink exists and has the correct target, no changes need to be made"
                            }
                        }
                    }
                    else{
                        Write-Verbose "Local folder does not exist"
                        if(!(Test-Path "$LinkPath\$Name")){
                            Write-Verbose "Does not exist in LinkPath"
                            New-Item -Path "$LinkPath\" -Name "$Name" -ItemType "directory" -Force
                            Write-Verbose "New folder created in LinkPath"
                        }
                        else{
                            Write-Verbose "Exists in LinkPath"
                        }
                        New-Item -Path $Path -ItemType SymbolicLink -Value "$LinkPath\$Name" -Force
                        Write-Verbose "Symlink created successfully"
                    }
                    Write-Host "No errors occured, applying changes"
                }
                catch{
                    Write-Host "An error occured, rolling back changes ($($Error[0]))"
                }
            }
        }
    }
    else{
        Write-Host "No symlinks.ini file found"
    }
    Write-Host "Done creating Symlinks"
}

function Setup-Hosts($Configuration = "default"){
    Write-Host "Setting up hosts file"
    if(Test-Path ".\$Configuration\hosts\from-file.txt"){
        Write-Verbose "Adding hosts from file"
        Add-Content -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Value (Get-Content -Path ".\$Configuration\hosts\from-file.txt")
        Write-Verbose "Done adding hosts from file"
    }
    else{
        Write-Verbose "No host from-file file found"
    }

    if(Test-Path ".\$Configuration\hosts\from-url.txt"){
        Write-Verbose "Adding hosts from url"
        foreach($Line in (Get-Content -Path ".\$Configuration\hosts\from-url.txt" | Where-Object {$_ -notlike ";*"})){
            Write-Verbose "Loading hosts from $Line"
            Add-Content -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Value (Invoke-WebRequest -URI $Line -UseBasicParsing).Content
            Write-Verbose "Done loading hosts from $Line"
        }
        Write-Verbose "Done adding hosts from url"
    }
    else{
        Write-Verbose "No host from-url file found"
    }
    Write-Host "Done setting up hosts file"
}

function Install-Programs($Configuration = "default"){
    Write-Host "Installing programs"
    foreach($ExeFile in Get-Childitem ".\$Configuration\install\*.exe"){
        Write-Verbose "Installing $ExeFile from file"
        & $ExeFile
        Write-Verbose "Done installing $ExeFile from file"
    }

    if(Test-Path ".\$Configuration\install\from-url.txt"){
        Write-Verbose "Installing from url"
        foreach($URL in (Get-Content ".\$Configuration\install\from-url.txt" | Where-Object {$_ -notlike ";*"})){
            Write-Verbose "Installing $URL from url"
            $Index++
            (New-Object System.Net.WebClient).DownloadFile($URL, "$($Env:TEMP)\$Index.exe")
            Start-Process -FilePath "$($Env:TEMP)\$Index.exe" -ArgumentList "/S" | Out-Null
            Write-Verbose "Done installing $URL from url"
        }
        Write-Verbose "Done installing from url"
    }
    else{
        Write-Host "No install from-url file found"
    }

    if(Test-Path ".\$Configuration\install\from-chocolatey.txt"){
        if(!(Get-Command "choco" -errorAction SilentlyContinue)){
            Write-Verbose "Installing chocolatey"
            $ChocolateyJob = Start-Job {
                Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
            }
            if($ChocolateyJob | Wait-Job -Timeout 120){
                Write-Verbose "Done installing chocolatey"
            }
            else{
                Stop-Job $ChocolateyJob
                Write-Verbose "Timeout while installing chocolatey, skipping..."
            }
        }
        if(Get-Command "choco" -errorAction SilentlyContinue){
            choco feature enable -n allowGlobalConfirmation -ErrorAction SilentlyContinue
            if(Test-Path ".\$Configuration\install\chocolatey-repository.ini"){
                Write-Verbose "Removing default repository and loading new repositories from file"
                choco source remove -n=chocolatey
                $Sources = Get-IniContent -FilePath ".\$Configuration\install\chocolatey-repository.ini" -IgnoreComments
                foreach($Source in $Sources.Keys){
                    $Splatter = $Sources[$Source]
                    choco source add --name $Source @Splatter
                }
                Write-Verbose "Done removing default repository and loading new repositories from file"
            }
            Write-Verbose "Installing from chocolatey"
            foreach($Install in (Get-Content ".\$Configuration\install\from-chocolatey.txt" | Where-Object {$_ -notlike ";*"})){
                Write-Verbose "Installing $Install from chocolatey"
                choco install $Install --limit-output --ignore-checksum
                choco pin add -n="$Install"
                Write-Verbose "Done installing $Install from chocolatey"
            }
        }
        else{
            Write-Verbose "Chocolatey not installed or requires a restart after install, not installing packages"
        }
        Write-Verbose "Done installing from chocolatey"
    }
    else{
        Write-Host "No install from-chocolatey file found"
    }

    if(Test-Path ".\$Configuration\install\from-winget.txt"){
        if(!(Get-Command "winget" -errorAction SilentlyContinue)){
            Write-Verbose "Installing winget"
            if(Start-Process "ms-appinstaller:?source=https://aka.ms/getwinget" -ErrorAction SilentlyContinue | Wait-Process -Timeout 120 -ErrorAction SilentlyContinue){
                Write-Verbose "Done installing winget"
            }
            else{
                Stop-Job $WingetJob
                Write-Verbose "Timout while installing winget, skipping..."
            }
        }
        if(Get-Command "winget" -errorAction SilentlyContinue){
            Write-Verbose "Installing from winget"
            foreach($Install in (Get-Content ".\$Configuration\install\from-winget.txt" | Where-Object {$_ -notlike ";*"})){
                Write-Verbose "Installing $Install from winget"
                winget install $Install
                Write-Verbose "Done installing $Install from winget"
            }
            Write-Verbose "Done installing from winget"
        }
        else{
            Write-Verbose "Winget not installed, not installing packages"
        }
        Write-Verbose "Done installing from winget"
    }
    else{
        Write-Host "No install from-winget file found"
    }

    Write-Host "Done installing programs"
}

function Remove-Bloatware($Configuration = "default"){
    if(Test-Path ".\$Configuration\install\remove-bloatware.txt"){
        Write-Host "Removing bloatware"
        foreach($AppxPackage in (Get-Content ".\$Configuration\install\remove-bloatware.txt" | Where-Object {$_ -notlike ";*"})){
            Write-Verbose "Removing $AppxPackage"
            Get-AppxPackage $AppxPackage | Remove-AppxPackage
            Write-Verbose "Done removing $AppxPackage"
        }
        Write-Host "Done removing bloatware"
    }
    else{
        Write-Host "No remove-bloatware file found"
    }
}

function Setup-Partitions($Configuration = "default"){
    Write-Host "Setting up partitions"
    if(Test-Path ".\$Configuration\settings\partitions.ini"){
        $Partitions = Get-IniContent -FilePath ".\$Configuration\settings\partitions.ini" -IgnoreComments
        #Find all driveletters that are wanted
        $UnusableDriveLetters = @()
        foreach($Drive in $Partitions.Keys){
            foreach($Partition in $Partitions["$Drive"].Keys){
                $UnusableDriveLetters += $Partitions["$Drive"]["$Partition"]
            }
        }
        Write-Verbose "Found all wanted driveletters: $UnusableDriveLetters"
        #Find all drive letters that are currently in use
        $UnusableDriveLetters += (Get-PSDrive).Root -match "^[A-Z]:\\"
        Write-Verbose "Found all wanted and currently used driveletters: $UnusableDriveLetters"
        #Find all free usable drive letters (Not currently used and not wanted)
        65..90|foreach-object{
            if(-not $UnusableDriveLetters.Contains("$([char]$_):\")){
                $UsableDriveLetters += [char]$_
            }
        }
        $UsableDriveLetterIndex = 0
        Write-Verbose "Found all freely usable drive letters (Not used  & not wanted): $UsableDriveLetters"
        #Temporarily assign all partitions to one of those letters
        foreach($Drive in $Partitions.Keys){
            foreach($Partition in $Partitions["$Drive"].Keys){
                Write-Verbose "Assigning partition $Partition of drive $Drive to temporary letter $($UsableDriveLetters[$UsableDriveLetterIndex])"
                Get-Disk | Where-Object SerialNumber -EQ "$Drive" | Get-Partition | Where-Object PartitionNumber -EQ $Partition | Set-Partition -NewDriveLetter $UsableDriveLetters[$UsableDriveLetterIndex]
                $UsableDriveLetterIndex++
                Write-Verbose "Done assigning partition $Partition of drive $Drive to temporary letter $($UsableDriveLetters[$UsableDriveLetterIndex])"
            }
        }
        Write-Verbose "All partitions set to temporary driveletters"
        #Assign all partitions to their wanted letter
        foreach($Drive in $Partitions.Keys){
            foreach($Partition in $Partitions["$Drive"].Keys){
                Write-Verbose "Assigning partition $Partition of drive $Drive to letter $($Partitions["$Drive"]["$Partition"])"
                Get-Disk | Where-Object SerialNumber -EQ "$Drive" | Get-Partition | Where-Object PartitionNumber -EQ $Partition | Set-Partition -NewDriveLetter $Partitions["$Drive"]["$Partition"]
                Write-Verbose "Done assigning partition $Partition of drive $Drive to letter $($Partitions["$Drive"]["$Partition"])"
            }
        }
        Write-Host "Done setting up partitions"
    }
    else{
        Write-Host "No partition file found"
    }
}

function Setup-Powershell($Configuration = "default"){
    Write-Host "Setting up Powershell"
    Update-Help -ErrorAction "silentlyContinue"
    if(Test-Path ".\$Configuration\powershell\packageprovider.txt"){
        Write-Verbose "Installing packageproviders"
        foreach($PackageProvider in (Get-Content ".\$Configuration\powershell\packageprovider.txt" | Where-Object {$_ -notlike ";*"})){
            if(Get-PackageProvider $PackageProvider -ErrorAction "silentlyContinue"){
                Write-Verbose "PackageProvider $PackageProvider is already installed, skipping..."
            }
            else{
                Write-Verbose "Installing packageprovider $PackageProvider"
                Install-PackageProvider -Name $PackageProvider -Force -Confirm:$False
                Write-Verbose "Done installing packageprovider $PackageProvider"
            }
        }
        Write-Verbose "Done installing packageproviders"
    }
    else{
        Write-Host "No powershell-packageprovider file found"
    }

    if(Test-Path ".\$Configuration\powershell\module.txt"){
        Write-Verbose "Installing modules"
        foreach($PowershellModule in (Get-Content ".\$Configuration\powershell\module.txt" | Where-Object {$_ -notlike ";*"})){
            if(Get-InstalledModule $PowershellModule -ErrorAction "silentlyContinue"){
                Write-Verbose "Module $PowershellModule is already installed, skipping..."
            }
            else{
                Write-Verbose "Installing module $PowershellModule"
                Install-Module -Name $PowershellModule -Force -Confirm:$False
                Write-Verbose "Done installing module $PowershellModule"
            }
        }
        Write-Verbose "Done installing modules"
    }
    else{
        Write-Host "No powershell-module file found"
    }
    Write-Host "Done setting up Powershell"
}



function Start-Setup($Configuration = "default"){
    Start-Transcript "$Home\Desktop\$(Get-Date -Format "yyyy_MM_dd")_setup.transcript"

    if(Test-Path ".\$Configuration\"){
        #Requirements
        "PsIni", "Recycle" | % {
            if(!(Get-InstalledModule $_ -ErrorAction SilentlyContinue)){
                Install-Module $_ -Force -ErrorAction Stop
                Import-Module $_ -Force -ErrorAction Stop
            }
        }
        Write-Host "Creating Windows Checkpoint"
        Checkpoint-Computer -Description "Before Start-Setup at $(Get-Date)"
        Read-Host "Checkpoint created. Press enter to continue"

        Write-Host "Stopping Windows update service"
        net stop wuauserv | Write-Host
        Read-Host "Windows update service stopped. Press enter to continue"


        if(Test-Path ".\prepend_custom.ps1"){
            & ".\$Configuration\scripts\prepend_custom.ps1"
        }
        Setup-Powershell -Configuration $Configuration
        Setup-Partitions -Configuration $Configuration
        Load-Registry -Configuration $Configuration
        Create-Symlinks -Configuration $Configuration
        Setup-Hosts -Configuration $Configuration
        Remove-Bloatware -Configuration $Configuration
        Install-Programs -Configuration $Configuration
        Setup-FileAssociations -Configuration $Configuration
        if(Test-Path ".\append_custom.ps1"){
            & ".\$Configuration\scripts\append_custom.ps1"
        }


        Write-Host "Creating Windows Checkpoint"
        Checkpoint-Computer -Description "After Start-Setup at $(Get-Date)"
        Read-Host "Checkpoint created. Press enter to continue"

        Write-Host "Starting Windows update service"
        net start wuauserv | Write-Host
        Write-Host "Windows update service started. Press enter to continue"
    }
    else{
        Write-Host "No Configuration $Configuration found, terminating execution."
    }

    Stop-Transcript
}