. .\functions.ps1


function Setup-FileAssociations($Group = "default"){
    Write-Output "Setting up file associations"
    $Associations = Get-IniContent -FilePath "$Group\settings\associations.ini" -IgnoreComments
    foreach($Extension in $Associations["associations"].Keys){
        Write-VerboseOutput "Creating association $($Associations[$Extension]) for file type $Extension"
        Create-Association $Extension $Associations[$Extension]
        Write-VerboseOutput "Done creating association $($Associations[$Extension]) for file type $Extension"
    }
    Write-Output "Done setting up file associations"
}

function Load-Registry($Group = "default"){
    if(Test-Path "$Group\settings\registry.reg"){
        Write-Output "Importing registry file"
        reg import "$Group\settings\registry.reg"
        Write-Output "Done importing registry file"
    }
    else{
        Write-Output "Cannot find registry file"
    }
}

function Create-Symlinks($Group = "default"){
    Write-Output "Creating Symlinks"
    if(Test-path "$Group\settings\symlinks.ini"){
        $IniContent = Get-IniContent -FilePath "$Group\settings\symlinks.ini" -IgnoreComments
        foreach($LinkPath in $IniContent.Keys){
            Write-VerboseOutput "Creating Symlinks for LinkPath $LinkPath"
            if(!(Test-Path $LinkPath)){
                New-Item $LinkPath -ItemType Directory -Force
            }
            $Links = $IniContent[$LinkPath]
            foreach($Name in $Links.Keys){
                $Path = $Links[$Name]
                Write-VerboseOutput "Create-Symlink: $Name | $($Path):"
                try{
                    if(Test-Path $Path){
                        Write-VerboseOutput "Local folder exists"
                        if(!(Test-Symlink "$Path")){
                            Write-VerboseOutput "Local folder is no Symlink yet"
                            if(!(Test-Path "$LinkPath\$Name")){
                                Write-VerboseOutput "Does not exist in LinkPath"
                                New-Item -Path "$LinkPath\" -Name "$Name" -ItemType "directory" -Force
                                Write-VerboseOutput "New folder created in LinkPath"
                            }
                            else{
                                Write-VerboseOutput "Exists in LinkPath"
                            }
                            Copy-Item -Path "$Path\*" -Destination "$LinkPath\$Name\" -Recurse
                            Write-VerboseOutput "Copied to LinkPath sucessfully"
                            Remove-ItemSafely -Path $Path -Recurse -Force
                            Write-VerboseOutput "Removed old folder"
                            New-Item -Path $Path -ItemType SymbolicLink -Value "$LinkPath\$Name" -Force
                            Write-VerboseOutput "SymLink created sucessfully"
                        }
                        else{
                            Write-VerboseOutput "Local folder is a SymLink already"
                            if(!(Test-Path "$LinkPath\$Name")){
                                Write-VerboseOutput "But does not exist in LinkPath"
                                New-Item -Path "$LinkPath\" -Name "$Name" -ItemType "directory" -Force
                                Write-VerboseOutput "New folder created in LinkPath"
                            }
                            else{
                                Write-VerboseOutput "Exists in LinkPath"
                            }
                            if((Get-SymlinkTarget $Path) -ne "$LinkPath\$Name"){
                                Write-VerboseOutput "Symlink exists, but has a wrong target"
                                Write-VerboseOutput "Target: $LinkPath\$Name"
                                Write-VerboseOutput "Wanted Target: $(Get-SymlinkTarget $Path)"
                                Copy-Item -Path "$Path\*" -Destination "$LinkPath\$Name\" -Recurse
                                Write-VerboseOutput "Everything copied from false target"
                                Remove-ItemSafely -Path $Path
                                Write-VerboseOutput "Old symlink removed"
                                New-Item -Path $Path -ItemType SymbolicLink -Value "$LinkPath\$Name" -Force
                                Write-VerboseOutput "New Symlink created"
                            }
                            else{
                                Write-VerboseOutput "Symlink exists and has the correct target, no changes need to be made"
                            }
                        }
                    }
                    else{
                        Write-VerboseOutput "Local folder does not exist"
                        if(!(Test-Path "$LinkPath\$Name")){
                            Write-VerboseOutput "Does not exist in LinkPath"
                            New-Item -Path "$LinkPath\" -Name "$Name" -ItemType "directory" -Force
                            Write-VerboseOutput "New folder created in LinkPath"
                        }
                        else{
                            Write-VerboseOutput "Exists in LinkPath"
                        }
                        New-Item -Path $Path -ItemType SymbolicLink -Value "$LinkPath\$Name" -Force
                        Write-VerboseOutput "Symlink created successfully"
                    }
                    Write-Output "No errors occured, applying changes"
                }
                catch{
                    Write-Output "An error occured, rolling back changes"
                }
            }
        }
    }
    else{
        Write-Output "No symlinks.ini file found"
    }
    Write-Output "Done creating Symlinks"
}

function Setup-Hosts($Group = "default"){
    Write-Output "Setting up hosts file"
    if(Test-Path "$Group\hosts\from-file.txt"){
        Write-VerboseOutput "Adding hosts from file"
        Add-Content -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Value (Get-Content -Path "$Group\hosts\from-file.txt")
        Write-VerboseOutput "Done adding hosts from file"
    }
    else{
        Write-VerboseOutput "No host from-file file found"
    }

    if(Test-Path "$Group\hosts\from-url.txt"){
        Write-VerboseOutput "Adding hosts from url"
        foreach($Line in (Get-Content -Path "$Group\hosts\from-url.txt" | Where-Object {$_ -notlike ";*"})){
            Write-VerboseOutput "Loading hosts from $Line"
            Add-Content -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Value (Invoke-WebRequest -URI $Line -UseBasicParsing).Content
            Write-VerboseOutput "Done loading hosts from $Line"
        }
        Write-VerboseOutput "Done adding hosts from url"
    }
    else{
        Write-VerboseOutput "No host from-url file found"
    }
    Write-Output "Done setting up hosts file"
}

function Setup-Quickaccess($Group = "default"){
    if(Test-Path "$Group\quickaccess\folders.txt"){
        Write-Output "Setting up quickaccess"
        foreach($Folder in (Get-Content "$Group\quickaccess\folders.txt" | Where-Object {$_ -notlike ";*"})){
            Write-VerboseOutput "Adding $Folder to quickaccess"
            (New-Object -com shell.application).Namespace($Folder).Self.InvokeVerb("pintohome")
            Write-VerboseOutput "Done adding $Folder to quickaccess"
        }
        Write-Output "Done setting up quickaccess"
    }
    else{
        Write-Output "No quickaccess file found"
    }
}

function Install-Programs($Group = "default"){
    Write-Output "Installing programs"
    foreach($ExeFile in Get-Childitem "$Group\install\*.exe"){
        Write-VerboseOutput "Installing $ExeFile from file"
        & $ExeFile
        Write-VerboseOutput "Done installing $ExeFile from file"
    }

    if(Test-Path "$Group\install\from-url.txt"){
        Write-VerboseOutput "Installing from url"
        foreach($URL in (Get-Content "$Group\install\from-url.txt" | Where-Object {$_ -notlike ";*"})){
            Write-VerboseOutput "Installing $URL from url"
            $Index++
            (New-Object System.Net.WebClient).DownloadFile($URL, "$($Env:TEMP)\$Index.exe")
            Start-Process -FilePath "$($Env:TEMP)\$Index.exe" -ArgumentList "/S" | Out-Null
            Write-VerboseOutput "Done installing $URL from url"
        }
        Write-VerboseOutput "Done installing from url"
    }
    else{
        Write-Output "No install from-url file found"
    }

    if(Test-Path "$Group\install\from-chocolatey.txt"){
        if(!(Get-Command "choco" -errorAction SilentlyContinue)){
            Write-VerboseOutput "Installing chocolatey"
            $ChocolateyJob = Start-Job {
                Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
            }
            if($ChocolateyJob | Wait-Job -Timeout 120){
                Write-Verbose "Done installing chocolatey"
            }
            else{
                Stop-Job $ChocolateyJob
                Write-VerboseOutput "Timeout while installing chocolatey, skipping..."
            }
        }
        if(Get-Command "choco" -errorAction SilentlyContinue){
            choco feature enable -n allowGlobalConfirmation -ErrorAction SilentlyContinue
            if(Test-Path "$Group\install\chocolatey-repository.ini"){
                Write-VerboseOutput "Removing default repository and loading new repositories from file"
                choco source remove -n=chocolatey
                $Sources = Get-IniContent -FilePath "$Group\install\chocolatey-repository.ini" -IgnoreComments
                foreach($Source in $Sources.Keys){
                    $Splatter = $Sources[$Source]
                    choco source add --name $Source @Splatter
                }
                Write-VerboseOutput "Done removing default repository and loading new repositories from file"
            }
            Write-VerboseOutput "Installing from chocolatey"
            foreach($Install in (Get-Content "$Group\install\from-chocolatey.txt" | Where-Object {$_ -notlike ";*"})){
                Write-VerboseOutput "Installing $Install from chocolatey"
                choco install $Install --limit-output --ignore-checksum
                choco pin add -n="$Install"
                Write-VerboseOutput "Done installing $Install from chocolatey"
            }
        }
        else{
            Write-VerboseOutput "Chocolatey not installed or requires a restart after install, not installing packages"
        }
        Write-VerboseOutput "Done installing from chocolatey"
    }
    else{
        Write-Output "No install from-chocolatey file found"
    }

    if(Test-Path "$Group\install\from-winget.txt"){
        if(!(Get-Command "winget" -errorAction SilentlyContinue)){
            Write-VerboseOutput "Installing winget"
            Start-Process "ms-appinstaller:?source=https://aka.ms/getwinget"
            $nid = (Get-Process AppInstaller).Id
            if(Wait-Process -Id $nid -Timeout 120){
                Write-VerboseOutput "Done installing winget"
            }
            else{
                Write-Output "Timout while installing winget, skipping..."
            }
        }
        if(Get-Command "winget" -errorAction SilentlyContinue){
            Write-VerboseOutput "Installing from winget"
            foreach($Install in (Get-Content "$Group\install\from-winget.txt" | Where-Object {$_ -notlike ";*"})){
                Write-VerboseOutput "Installing $Install from winget"
                winget install $Install
                Write-VerboseOutput "Done installing $Install from winget"
            }
            Write-VerboseOutput "Done installing from winget"
        }
        else{
            Write-VerboseOutput "Winget not installed, not installing packages"
        }
        Write-VerboseOutput "Done installing from winget"
    }
    else{
        Write-Output "No install from-winget file found"
    }

    Write-Output "Done installing programs"
}

function Remove-Bloatware($Group = "default"){
    if(Test-Path "$Group\install\remove-bloatware.txt"){
        Write-Output "Removing bloatware"
        foreach($AppxPackage in (Get-Content "$Group\install\remove-bloatware.txt" | Where-Object {$_ -notlike ";*"})){
            Write-VerboseOutput "Removing $AppxPackage"
            Get-AppxPackage $AppxPackage | Remove-AppxPackage
            Write-VerboseOutput "Done removing $AppxPackage"
        }
        Write-Output "Done removing bloatware"
    }
    else{
        Write-Output "No remove-bloatware file found"
    }
}

function Setup-Partitions($Group = "default"){
    Write-Output "Setting up partitions"
    if(Test-Path "$Group\settings\partitions.ini"){
        $Partitions = Get-IniContent -FilePath "$Group\settings\partitions.ini" -IgnoreComments
        #Find all driveletters that are wanted
        $UnusableDriveLetters = @()
        foreach($Drive in $Partitions.Keys){
            foreach($Partition in $Partitions["$Drive"].Keys){
                $UnusableDriveLetters += $Partitions["$Drive"]["$Partition"]
            }
        }
        Write-VerboseOutput "Found all wanted driveletters: $UnusableDriveLetters"
        #Find all drive letters that are currently in use
        $UnusableDriveLetters += (Get-PSDrive).Root -match "^[A-Z]:\\"
        Write-VerboseOutput "Found all wanted and currently used driveletters: $UnusableDriveLetters"
        #Find all free usable drive letters (Not currently used and not wanted)
        65..90|foreach-object{
            if(-not $UnusableDriveLetters.Contains("$([char]$_):\")){
                $UsableDriveLetters += [char]$_
            }
        }
        $UsableDriveLetterIndex = 0
        Write-VerboseOutput "Found all freely usable drive letters (Not used  & not wanted): $UsableDriveLetters"
        #Temporarily assign all partitions to one of those letters
        foreach($Drive in $Partitions.Keys){
            foreach($Partition in $Partitions["$Drive"].Keys){
                Write-VerboseOutput "Assigning partition $Partition of drive $Drive to temporary letter $($UsableDriveLetters[$UsableDriveLetterIndex])"
                Get-Disk | Where-Object SerialNumber -EQ "$Drive" | Get-Partition | Where-Object PartitionNumber -EQ $Partition | Set-Partition -NewDriveLetter $UsableDriveLetters[$UsableDriveLetterIndex]
                $UsableDriveLetterIndex++
                Write-VerboseOutput "Done assigning partition $Partition of drive $Drive to temporary letter $($UsableDriveLetters[$UsableDriveLetterIndex])"
            }
        }
        Write-VerboseOutput "All partitions set to temporary driveletters"
        #Assign all partitions to their wanted letter
        foreach($Drive in $Partitions.Keys){
            foreach($Partition in $Partitions["$Drive"].Keys){
                Write-VerboseOutput "Assigning partition $Partition of drive $Drive to letter $($Partitions["$Drive"]["$Partition"])"
                Get-Disk | Where-Object SerialNumber -EQ "$Drive" | Get-Partition | Where-Object PartitionNumber -EQ $Partition | Set-Partition -NewDriveLetter $Partitions["$Drive"]["$Partition"]
                Write-VerboseOutput "Done assigning partition $Partition of drive $Drive to letter $($Partitions["$Drive"]["$Partition"])"
            }
        }
        Write-Output "Done setting up partitions"
    }
    else{
        Write-Output "No partition file found"
    }
}

function Setup-Powershell($Group = "default"){
    Write-Output "Setting up Powershell"
    #Update-Help -ErrorAction "silentlyContinue"
    if(Test-Path "$Group\powershell\packageprovider.txt"){
        Write-VerboseOutput "Installing packageproviders"
        foreach($PackageProvider in (Get-Content "$Group\powershell\packageprovider.txt" | Where-Object {$_ -notlike ";*"})){
            if(Get-PackageProvider $PackageProvider -ErrorAction "silentlyContinue"){
                Write-VerboseOutput "PackageProvider $PackageProvider is already installed, skipping..."
            }
            else{
                Write-VerboseOutput "Installing packageprovider $PackageProvider"
                Install-PackageProvider -Name $PackageProvider -Force -Confirm:$False
                Write-VerboseOutput "Done installing packageprovider $PackageProvider"
            }
        }
        Write-VerboseOutput "Done installing packageproviders"
    }
    else{
        Write-Output "No powershell-packageprovider file found"
    }

    if(Test-Path "$Group\powershell\module.txt"){
        Write-VerboseOutput "Installing modules"
        foreach($PowershellModule in (Get-Content "$Group\powershell\module.txt" | Where-Object {$_ -notlike ";*"})){
            if(Get-InstalledModule $PowershellModule -ErrorAction "silentlyContinue"){
                Write-VerboseOutput "Module $PowershellModule is already installed, skipping..."
            }
            else{
                Write-VerboseOutput "Installing module $PowershellModule"
                Install-Module -Name $PowershellModule -Force -Confirm:$False
                Write-VerboseOutput "Done installing module $PowershellModule"
            }
        }
        Write-VerboseOutput "Done installing modules"
    }
    else{
        Write-Output "No powershell-module file found"
    }
    Write-Output "Done setting up Powershell"
}



function Start-Setup(){
    [Cmdletbinding()]
    param([String] $Group = "default")

    Workflow Setup{
        [Cmdletbinding()]
        param([String] $Group)
        #Start-Transcript "$Home\Desktop\$(Get-Date -Format "yyyy_MM_dd")_setup.transcript"

        if(Test-Path "$Group\"){
            Write-Output "Creating Windows Checkpoint"
            Checkpoint-Computer -Description "Before Start-Setup at $(Get-Date)"
            Write-Output "Checkpoint created. Press enter to continue"

            Write-Output "Stopping Windows update service"
            net stop wuauserv | Write-Output
            Write-Output "Windows update service stopped. Press enter to continue"

            if(Test-Path ".\prepend_custom.ps1"){
                #& "$Group\scripts\prepend_custom.ps1"
            }
            Setup-Powershell -Group $Group
            Setup-Partitions -Group $Group
            Load-Registry -Group $Group
            Create-Symlinks -Group $Group
            #Setup-FileAssociations -Group $Group
            Setup-Hosts -Group $Group
            Setup-Quickaccess -Group $Group
            Remove-Bloatware -Group $Group
            Install-Programs -Group $Group
            if(Test-Path ".\append_custom.ps1"){
                #& "$Group\scripts\append_custom.ps1"
            }


            Write-Output "Creating Windows Checkpoint"
            Checkpoint-Computer -Description "After Start-Setup at $(Get-Date)"
            Write-Output "Checkpoint created. Press enter to continue"

            Write-Output "Starting Windows update service"
            net start wuauserv | Write-Output
            Write-Output "Windows update service started. Press enter to continue"
        }
        else{
            Write-Output "No group $Group found, terminating execution."
        }

        #Stop-Transcript
    }
    Setup -Group "$(Get-Location)\$Group" -AsJob
}