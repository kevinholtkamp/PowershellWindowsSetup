. .\functions.ps1


function Setup-FileAssociations($Associations){
    Write-Host "Setting up file associations"
    foreach($Extension in $Associations.Keys){
        Write-Debug "Creating association $($Associations[$Extension]) for file type $Extension"
        Create-Association $Extension $Associations[$Extension]
        Write-Debug "Done creating association $($Associations[$Extension]) for file type $Extension"
    }
    Write-Host "Done setting up file associations"
}

function Load-Registry($Group = "default"){
    if(Test-Path ".\$Group\settings\registry.reg"){
        Write-Host "Importing registry file"
        reg import ".\$Group\settings\registry.reg"
        Write-Host "Done importing registry file"
    }
    else{
        Write-Host "Cannot find registry file"
    }
}

function Create-Symlinks($Group = "default"){
    Write-Host "Creating Symlinks"
    if(Test-path ".\$Group\settings\symlinks.ini"){
        $IniContent = Get-IniContent -FilePath ".\$Group\settings\symlinks.ini" -IgnoreComments
        foreach($LinkPath in $IniContent.Keys){
            Write-Debug "Creating Symlinks for LinkPath $LinkPath"
            if(!(Test-Path $LinkPath)){
                New-Item $LinkPath -ItemType Directory
            }
            $Links = $IniContent[$LinkPath]
            foreach($Name in $Links.Keys){
                $Path = $Links[$Name]
                Write-Debug "Create-Symlink: $Name | $($Path):"
                try{
                    if(Test-Path $Path){
                        Write-Debug "Local folder exists"
                        if(!(Test-Symlink "$Path")){
                            Write-Debug "Local folder is no Symlink yet"
                            if(!(Test-Path "$LinkPath\$Name")){
                                Write-Debug "Does not exist in LinkPath"
                                New-Item -Path "$LinkPath\" -Name "$Name" -ItemType "directory"
                                Write-Debug "New folder created in LinkPath"
                            }
                            else{
                                Write-Debug "Exists in LinkPath"
                            }
                            Copy-Item -Path "$Path\*" -Destination "$LinkPath\$Name\" -Recurse
                            Write-Debug "Copied to LinkPath sucessfully"
                            Remove-ItemSafely -Path $Path -Recurse -Force
                            Write-Debug "Removed old folder"
                            New-Item -Path $Path -ItemType SymbolicLink -Value "$LinkPath\$Name"
                            Write-Debug "SymLink created sucessfully"
                        }
                        else{
                            Write-Debug "Local folder is a SymLink already"
                            if(!(Test-Path "$LinkPath\$Name")){
                                Write-Debug "But does not exist in LinkPath"
                                New-Item -Path "$LinkPath\" -Name "$Name" -ItemType "directory"
                                Write-Debug "New folder created in LinkPath"
                            }
                            else{
                                Write-Debug "Exists in LinkPath"
                            }
                            if((Get-SymlinkTarget $Path) -ne "$LinkPath\$Name"){
                                Write-Debug "Symlink exists, but has a wrong target"
                                Write-Debug "Target: $LinkPath\$Name"
                                Write-Debug "Wanted Target: $(Get-SymlinkTarget $Path)"
                                Copy-Item -Path "$Path\*" -Destination "$LinkPath\$Name\" -Recurse
                                Write-Debug "Everything copied from false target"
                                Remove-ItemSafely -Path $Path
                                Write-Debug "Old symlink removed"
                                New-Item -Path $Path -ItemType SymbolicLink -Value "$LinkPath\$Name"
                                Write-Debug "New Symlink created"
                            }
                            else{
                                Write-Debug "Symlink exists and has the correct target, no changes need to be made"
                            }
                        }
                    }
                    else{
                        Write-Debug "Local folder does not exist"
                        if(!(Test-Path "$LinkPath\$Name")){
                            Write-Debug "Does not exist in LinkPath"
                            New-Item -Path "$LinkPath\" -Name "$Name" -ItemType "directory" -Force
                            Write-Debug "New folder created in LinkPath"
                        }
                        else{
                            Write-Debug "Exists in LinkPath"
                        }
                        New-Item -Path $Path -ItemType SymbolicLink -Value "$LinkPath\$Name" -Force
                        Write-Debug "Symlink created successfully"
                    }
                    Write-Host "No errors occured, applying changes"
                }
                catch{
                    Write-Host "An error occured, rolling back changes"
                }
            }
        }
    }
    else{
        Write-Host "No symlinks.ini file found"
    }
    Write-Host "Done creating Symlinks"
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
        foreach($Line in (Get-Content -Path ".\$Group\hosts\from-url.txt" | Where-Object {$_ -notlike ";*"})){
            Write-Debug "Loading hosts from $Line"
            Add-Content -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Value (Invoke-WebRequest -URI $Line -UseBasicParsing).Content
            Write-Debug "Done loading hosts from $Line"
        }
        Write-Debug "Done adding hosts from url"
    }
    else{
        Write-Debug "No host from-url file found"
    }
    Write-Host "Done setting up hosts file"
}

function Setup-Quickaccess($Group = "default"){
    if(Test-Path ".\$Group\quickaccess\folders.txt"){
        Write-Host "Setting up quickaccess"
        foreach($Folder in (Get-Content ".\$Group\quickaccess\folders.txt" | Where-Object {$_ -notlike ";*"})){
            Write-Debug "Adding $Folder to quickaccess"
            (New-Object -com shell.application).Namespace($Folder).Self.InvokeVerb("pintohome")
            Write-Debug "Done adding $Folder to quickaccess"
        }
        Write-Host "Done setting up quickaccess"
    }
    else{
        Write-Host "No quickaccess file found"
    }
}

function Install-Programs($Group = "default"){
    Write-Host "Installing programs"
    foreach($ExeFile in Get-Childitem ".\$Group\install\*.exe"){
        Write-Debug "Installing $ExeFile from file"
        & $ExeFile
        Write-Debug "Done installing $ExeFile from file"
    }

    if(Test-Path ".\$Group\install\from-url.txt"){
        Write-Debug "Installing from url"
        foreach($URL in (Get-Content ".\$Group\install\from-url.txt" | Where-Object {$_ -notlike ";*"})){
            Write-Debug "Installing $URL from url"
            $Index++
            (New-Object System.Net.WebClient).DownloadFile($URL, "$($Env:TEMP)\$Index.exe")
            Start-Process -FilePath "$($Env:TEMP)\$Index.exe" -ArgumentList "/S" | Out-Null
            Write-Debug "Done installing $URL from url"
        }
        Write-Debug "Done installing from url"
    }
    else{
        Write-Host "No install from-url file found"
    }

    if(Test-Path ".\$Group\install\from-chocolatey.txt"){
        if(!(Get-Command "choco" -errorAction SilentlyContinue)){
            Write-Debug "Installing chocolatey"
            $ChocolateyJob = Start-Job {
                Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
            }
            if($ChocolateyJob | Wait-Job -Timeout 120){
                Write-Debug "Done installing chocolatey"
            }
            else{
                Stop-Job $ChocolateyJob
                Write-Debug "Timeout while installing chocolatey, skipping..."
            }
        }
        if(Get-Command "choco" -errorAction SilentlyContinue){
            choco feature enable -n allowGlobalConfirmation -ErrorAction SilentlyContinue
            if(Test-Path ".\$Group\install\chocolatey-repository.ini"){
                Write-Debug "Removing default repository and loading new repositories from file"
                choco source remove -n=chocolatey
                $Sources = Get-IniContent -FilePath ".\$Group\install\chocolatey-repository.ini" -IgnoreComments
                foreach($Source in $Sources.Keys){
                    $Splatter = $Sources[$Source]
                    choco source add --name $Source @Splatter
                }
                Write-Debug "Done removing default repository and loading new repositories from file"
            }
            Write-Debug "Installing from chocolatey"
            foreach($Install in (Get-Content ".\$Group\install\from-chocolatey.txt" | Where-Object {$_ -notlike ";*"})){
                Write-Debug "Installing $Install from chocolatey"
                choco install $Install --limit-output --ignore-checksum
                choco pin add -n="$Install"
                Write-Debug "Done installing $Install from chocolatey"
            }
        }
        else{
            Write-Debug "Chocolatey not installed or requires a restart after install, not installing packages"
        }
        Write-Debug "Done installing from chocolatey"
    }
    else{
        Write-Host "No install from-chocolatey file found"
    }

    if(Test-Path ".\$Group\install\from-winget.txt"){
        if(!(Get-Command "winget" -errorAction SilentlyContinue)){
            Write-Debug "Installing winget"
            $WingetJob = Start-Job {
                (New-Object System.Net.WebClient).DownloadFile("https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.1", "$($Env:TEMP)\microsoft.ui.xaml.zip")
                Expand-Archive -Path "$($Env:TEMP)\microsoft.ui.xaml.zip" -DestinationPath "$($Env:PSModulePath.Split(';')[0])\microsoft.ui.xaml\"
                (New-Object System.Net.WebClient).DownloadFile("https://github.com/microsoft/winget-cli/releases/download/v1.3.431/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle", "$($Env:TEMP)\winget.msixbundle")
                Add-AppxPackage -Path "$($Env:TEMP)\winget.msixbundle"
            }
            if($WingetJob | Wait-Job -Timeout 120){
                Write-Debug "Done installing winget"
            }
            else{
                Stop-Job $WingetJob
                Write-Debug "Timout while installing winget, skipping..."
            }
        }
        if(Get-Command "winget" -errorAction SilentlyContinue){
            Write-Debug "Installing from winget"
            foreach($Install in (Get-Content ".\$Group\install\from-winget.txt" | Where-Object {$_ -notlike ";*"})){
                Write-Debug "Installing $Install from winget"
                winget install $Install
                Write-Debug "Done installing $Install from winget"
            }
            Write-Debug "Done installing from winget"
        }
        else{
            Write-Debug "Winget not installed, not installing packages"
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
        foreach($AppxPackage in (Get-Content ".\$Group\install\remove-bloatware.txt" | Where-Object {$_ -notlike ";*"})){
            Write-Debug "Removing $AppxPackage"
            Get-AppxPackage $AppxPackage | Remove-AppxPackage
            Write-Debug "Done removing $AppxPackage"
        }
        Write-Host "Done removing bloatware"
    }
    else{
        Write-Host "No remove-bloatware file found"
    }
}

function Setup-Partitions($Group = "default"){
    Write-Host "Setting up partitions"
    if(Test-Path ".\$Group\settings\partitions.ini"){
        $Partitions = Get-IniContent -FilePath ".\$Group\settings\partitions.ini" -IgnoreComments
        #Find all driveletters that are wanted
        $UnusableDriveLetters = @()
        foreach($Drive in $Partitions.Keys){
            foreach($Partition in $Partitions["$Drive"].Keys){
                $UnusableDriveLetters += $Partitions["$Drive"]["$Partition"]
            }
        }
        Write-Debug "Found all wanted driveletters: $UnusableDriveLetters"
        #Find all drive letters that are currently in use
        $UnusableDriveLetters += (Get-PSDrive).Root -match "^[A-Z]:\\"
        Write-Debug "Found all wanted and currently used driveletters: $UnusableDriveLetters"
        #Find all free usable drive letters (Not currently used and not wanted)
        65..90|foreach-object{
            if(-not $UnusableDriveLetters.Contains("$([char]$_):\")){
                $UsableDriveLetters += [char]$_
            }
        }
        $UsableDriveLetterIndex = 0
        Write-Debug "Found all freely usable drive letters (Not used  & not wanted): $UsableDriveLetters"
        #Temporarily assign all partitions to one of those letters
        foreach($Drive in $Partitions.Keys){
            foreach($Partition in $Partitions["$Drive"].Keys){
                Write-Debug "Assigning partition $Partition of drive $Drive to temporary letter $($UsableDriveLetters[$UsableDriveLetterIndex])"
                Get-Disk | Where-Object SerialNumber -EQ "$Drive" | Get-Partition | Where-Object PartitionNumber -EQ $Partition | Set-Partition -NewDriveLetter $UsableDriveLetters[$UsableDriveLetterIndex]
                $UsableDriveLetterIndex++
                Write-Debug "Done assigning partition $Partition of drive $Drive to temporary letter $($UsableDriveLetters[$UsableDriveLetterIndex])"
            }
        }
        Write-Debug "All partitions set to temporary driveletters"
        #Assign all partitions to their wanted letter
        foreach($Drive in $Partitions.Keys){
            foreach($Partition in $Partitions["$Drive"].Keys){
                Write-Debug "Assigning partition $Partition of drive $Drive to letter $($Partitions["$Drive"]["$Partition"])"
                Get-Disk | Where-Object SerialNumber -EQ "$Drive" | Get-Partition | Where-Object PartitionNumber -EQ $Partition | Set-Partition -NewDriveLetter $Partitions["$Drive"]["$Partition"]
                Write-Debug "Done assigning partition $Partition of drive $Drive to letter $($Partitions["$Drive"]["$Partition"])"
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
        foreach($PackageProvider in (Get-Content ".\$Group\install\powershell-packageprovider.txt" | Where-Object {$_ -notlike ";*"})){
            if(Get-PackageProvider $PackageProvider -ErrorAction "silentlyContinue"){
                Write-Debug "PackageProvider $PackageProvider is already installed, skipping..."
            }
            else{
                Write-Debug "Installing packageprovider $PackageProvider"
                Install-PackageProvider -Name $PackageProvider -Force -Confirm:$False
                Write-Debug "Done installing packageprovider $PackageProvider"
            }
        }
        Write-Debug "Done installing packageproviders"
    }
    else{
        Write-Host "No powershell-packageprovider file found"
    }

    if(Test-Path ".\$Group\install\powershell-module.txt"){
        Write-Debug "Installing modules"
        foreach($PowershellModule in (Get-Content ".\$Group\install\powershell-module.txt" | Where-Object {$_ -notlike ";*"})){
            if(Get-InstalledModule $PowershellModule -ErrorAction "silentlyContinue"){
                Write-Debug "Module $PowershellModule is already installed, skipping..."
            }
            else{
                Write-Debug "Installing module $PowershellModule"
                Install-Module -Name $PowershellModule -Force -Confirm:$False
                Write-Debug "Done installing module $PowershellModule"
            }
        }
        Write-Debug "Done installing modules"
    }
    else{
        Write-Host "No powershell-module file found"
    }
    Write-Host "Done setting up Powershell"
}



function Start-Setup($Group = "default"){
    Start-Transcript "$Home\Desktop\$(Get-Date -Format "yyyy_MM_dd")_setup.transcript"

    if(Test-Path ".\$Group\"){
        Write-Host "Creating Windows Checkpoint"
        Checkpoint-Computer -Description "Before Start-Setup at $(Get-Date)"
        Read-Host "Checkpoint created. Press enter to continue"

        Write-Host "Stopping Windows update service"
        net stop wuauserv | Write-Host
        Read-Host "Windows update service stopped. Press enter to continue"


        if(Test-Path ".\prepend_custom.ps1"){
            & ".\$Group\scripts\prepend_custom.ps1"
        }
        $IniContent = Get-IniContent -FilePath ".\$Group\settings\settings.ini" -IgnoreComments

        Setup-Powershell -Group $Group
        Setup-Partitions -Group $Group
        Load-Registry -Group $Group
        Create-Symlinks -Group $Group
        Setup-FileAssociations -Associations $IniContent["associations"]
        Setup-Hosts -Group $Group
        Setup-Quickaccess -Group $Group
        Remove-Bloatware -Group $Group
        Install-Programs -Group $Group
        if(Test-Path ".\append_custom.ps1"){
            & ".\$Group\scripts\append_custom.ps1"
        }


        Write-Host "Creating Windows Checkpoint"
        Checkpoint-Computer -Description "After Start-Setup at $(Get-Date)"
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