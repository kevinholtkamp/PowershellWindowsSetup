param(
    [Parameter(Position = 0)]
    [String] $Configuration = "default",

    [Parameter(Position = 1)]
    [String] $ProgressColor = "Green"
)

function Setup-Powershell(){
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [String[]] $Modules,

        [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
        [String[]] $PackageProviders
    )
    Write-Host "Setting up Powershell" -ForegroundColor $ProgressColor

    Update-Help -ErrorAction "silentlyContinue"

    if($PackageProviders){
        Write-Verbose "Installing packageproviders from parameter"
        foreach($PackageProvider in $PackageProviders){
            if(Get-PackageProvider $PackageProvider -ErrorAction "silentlyContinue"){
                Write-Verbose "PackageProvider $PackageProvider is already installed, skipping..."
            }
            else{
                Write-Verbose "Installing packageprovider $PackageProvider"
                Install-PackageProvider -Name $PackageProvider -Force -Confirm:$False
                Write-Verbose "Done installing packageprovider $PackageProvider"
            }
        }
        Write-Verbose "Done installing packageproviders from parameter"
    }

    if($Modules){
        Write-Verbose "Installing modules from parameter"
        foreach($PowershellModule in $Modules){
            if(Get-InstalledModule $PowershellModule -ErrorAction "silentlyContinue"){
                Write-Verbose "Module $PowershellModule is already installed, skipping..."
            }
            else{
                Write-Verbose "Installing module $PowershellModule"
                Install-Module -Name $PowershellModule -Force -Confirm:$False
                Write-Verbose "Done installing module $PowershellModule"
            }
        }
        Write-Verbose "Done installing modules from parameter"
    }
    else{
        Write-Verbose "No powershell modules passed"
    }

    Write-Host "Done setting up Powershell" -ForegroundColor $ProgressColor
}

function Setup-Network(){
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ParameterSetName = 'IniContent', ValueFromPipeline = $true)]
        [Hashtable] $Interfaces,

        [Parameter(Position = 1, ParameterSetName = 'IniContent')]
        [Hashtable] $DNSServers
    )
    Write-Host "Setting up network" -ForegroundColor $ProgressColor

    foreach($InterfaceAlias in $Interfaces.Keys){
        Write-Verbose "Setting up interface $InterfaceAlias"
        $Interface = $Interfaces[$InterfaceAlias]
        Remove-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily $Interface["AddressFamily"]
        if($Interface["DefaultGateway"]){
            Remove-NetRoute -InterfaceAlias $InterfaceAlias
        }
        New-NetIPAddress -InterfaceAlias $InterfaceAlias @Interface

    }

    foreach($InterfaceAlias in $DNSServers.Keys){
        Write-Verbose "Setting up DNS for interface $InterfaceAlias"
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses @($DNSServers[$InterfaceAlias]["Primary"], $DNSServers[$InterfaceAlias]["Secondary"])
    }

    Write-Host "Done setting up network" -ForegroundColor $ProgressColor
}

function Setup-Partitions(){
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ParameterSetName = 'IniContent', ValueFromPipeline = $true)]
        [Hashtable] $IniContent
    )
    Write-Host "Setting up partitions" -ForegroundColor $ProgressColor

    if($IniContent){
        if($null -ne $IniContent){
            #Find all driveletters that are wanted
            $UnusableDriveLetters = @()
            foreach($Drive in $IniContent.Keys){
                foreach($Partition in $IniContent["$Drive"].Keys){
                    $UnusableDriveLetters += $IniContent["$Drive"]["$Partition"]
                }
            }
            Write-Verbose "Found all wanted driveletters: $UnusableDriveLetters"
            #Find all drive letters that are currently in use
            $UnusableDriveLetters += ((Get-PSDrive).Root -match "^[A-Z]:\\").Substring(0, 1)
            Write-Verbose "Found all wanted and currently used driveletters: $UnusableDriveLetters"
            #Find all free usable drive letters (Not currently used and not wanted)
            65..90|foreach-object{
                if(-not $UnusableDriveLetters.Contains("$([char]$_)")){
                    $UsableDriveLetters += [char]$_
                }
            }
            $UsableDriveLetterIndex = 0
            Write-Verbose "Found all freely usable drive letters (Not used  & not wanted): $UsableDriveLetters"
            #Temporarily assign all partitions to one of those letters
            foreach($Drive in $IniContent.Keys){
                foreach($Partition in $IniContent["$Drive"].Keys){
                    Write-Verbose "Assigning partition $Partition of drive $Drive to temporary letter $($UsableDriveLetters[$UsableDriveLetterIndex])"
                    Get-Disk | Where-Object SerialNumber -EQ "$Drive" | Get-Partition | Where-Object PartitionNumber -EQ $Partition | Set-Partition -NewDriveLetter $UsableDriveLetters[$UsableDriveLetterIndex]
                    Write-Verbose "Done assigning partition $Partition of drive $Drive to temporary letter $($UsableDriveLetters[$UsableDriveLetterIndex])"
                    $UsableDriveLetterIndex++
                }
            }
            Write-Verbose "All partitions set to temporary driveletters"
            #Assign all partitions to their wanted letter
            foreach($Drive in $IniContent.Keys){
                foreach($Partition in $IniContent["$Drive"].Keys){
                    Write-Verbose "Assigning partition $Partition of drive $Drive to letter $($IniContent["$Drive"]["$Partition"])"
                    $DriveObject = Get-Disk | Where-Object SerialNumber -EQ "$Drive"
                    $PartitionObject = Get-Partition -Disk $DriveObject | Where-Object PartitionNumber -EQ $Partition
                    Set-Partition -InputObject $PartitionObject -NewDriveLetter $IniContent["$Drive"]["$Partition"]
                    Write-Verbose "Done assigning partition $Partition of drive $Drive to letter $($IniContent["$Drive"]["$Partition"])"
                }
            }
        }
        else{
            Write-Host "Ini content is empty" -ForegroundColor $ProgressColor
        }
    }
    else{
        Write-Host "No partition file found" -ForegroundColor $ProgressColor
    }

    Write-Host "Done setting up partitions" -ForegroundColor $ProgressColor
}

function Create-Symlinks(){
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ParameterSetName = 'IniContent', ValueFromPipeline = $true)]
        [Hashtable] $IniContent
    )
    Write-Host "Creating Symlinks" -ForegroundColor $ProgressColor

    if($IniContent){
        foreach($BaseTargetFolder in $IniContent.Keys){
            Write-Verbose "Creating Symlinks for LinkPath $BaseTargetFolder"
            if(!(Test-Path $BaseTargetFolder)){
                New-Item $BaseTargetFolder -ItemType Directory -Force
            }
            $EntriesInBaseFolder = $IniContent[$BaseTargetFolder]
            foreach($TargetFolder in $EntriesInBaseFolder.Keys){
                $SourceFolder = $EntriesInBaseFolder[$TargetFolder]
                Write-Verbose "Create-Symlink: $TargetFolder | $($SourceFolder):"
                try{
                    & {
                        $ErrorActionPreference = "stop"
                        if(Test-Path $SourceFolder){
                            Write-Verbose "Local folder exists"
                            if(!(Test-Symlink "$SourceFolder")){
                                Write-Verbose "Local folder is no Symlink yet"
                                if(!(Test-Path "$BaseTargetFolder\$TargetFolder")){
                                    Write-Verbose "Does not exist in LinkPath"
                                    New-Item -Path "$BaseTargetFolder\" -Name "$TargetFolder" -ItemType "directory" -Force
                                    Write-Verbose "New folder created in LinkPath"
                                }
                                else{
                                    Write-Verbose "Exists in LinkPath"
                                }
                                Copy-Item -Path "$SourceFolder\*" -Destination "$BaseTargetFolder\$TargetFolder\" -Recurse -Force
                                Write-Verbose "Copied to LinkPath sucessfully"
                                Remove-ItemSafely -Path $SourceFolder -Recurse -Force
                                Write-Verbose "Removed old folder"
                                New-Item -Path $SourceFolder -ItemType SymbolicLink -Value "$BaseTargetFolder\$TargetFolder" -Force
                                Write-Verbose "SymLink created sucessfully"
                            }
                            else{
                                Write-Verbose "Local folder is a SymLink already"
                                if(!(Test-Path "$BaseTargetFolder\$TargetFolder")){
                                    Write-Verbose "But does not exist in LinkPath"
                                    New-Item -Path "$BaseTargetFolder\" -Name "$TargetFolder" -ItemType "directory" -Force
                                    Write-Verbose "New folder created in LinkPath"
                                }
                                else{
                                    Write-Verbose "Exists in LinkPath"
                                }
                                if(Compare-Paths -First $SourceFolder -Second "$BaseTargetFolder\$TargetFolder"){
                                    Write-Verbose "Symlink exists, but has a wrong target"
                                    Write-Verbose "Target: $BaseTargetFolder\$TargetFolder"
                                    Write-Verbose "Wanted Target: $(Get-SymlinkTarget $SourceFolder)"
                                    Copy-Item -Path "$SourceFolder\*" -Destination "$BaseTargetFolder\$TargetFolder\" -Recurse -Force
                                    Write-Verbose "Everything copied from false target"
                                    Remove-ItemSafely -Path $SourceFolder
                                    Write-Verbose "Old symlink removed"
                                    New-Item -Path $SourceFolder -ItemType SymbolicLink -Value "$BaseTargetFolder\$TargetFolder" -Force
                                    Write-Verbose "New Symlink created"
                                }
                                else{
                                    Write-Verbose "Symlink exists and has the correct target, no changes need to be made"
                                }
                            }
                        }
                        else{
                            Write-Verbose "Local folder does not exist"
                            if(!(Test-Path "$BaseTargetFolder\$TargetFolder")){
                                Write-Verbose "Does not exist in LinkPath"
                                New-Item -Path "$BaseTargetFolder\" -Name "$TargetFolder" -ItemType "directory" -Force
                                Write-Verbose "New folder created in LinkPath"
                            }
                            else{
                                Write-Verbose "Exists in LinkPath"
                            }
                            New-Item -Path $SourceFolder -ItemType SymbolicLink -Value "$BaseTargetFolder\$TargetFolder" -Force
                            Write-Verbose "Symlink created successfully"
                        }
                        Write-Host "No errors occured, applying changes"
                    }
                }
                catch{
                    if($ErrorActionPreference -eq "Stop"){
                        throw "An error occured; stopping symlink creation"
                    }
                    else{
                        Write-Error "An error occured; stopping current symlink creation"
                    }
                }
            }
        }
    }
    else{
        Write-Host "Ini content is empty" -ForegroundColor $ProgressColor
    }

    Write-Host "Done creating Symlinks" -ForegroundColor $ProgressColor
}

function Load-Registry(){
    [CmdletBinding()]
    param(
        [Parameter(Position = 1)]
        [HashTable] $RegistryData
    )
    Write-Host "Loading registry" -ForegroundColor $ProgressColor

    if($RegistryData){
        Write-Verbose "Parameter RegistryData"
        New-PSDrive -Name HKU -PsProvider Registry HKEY_USERS | out-null
        foreach($path in $RegistryData.Keys){
            Write-Verbose "Looping values for $path"
            $items = $RegistryData[$path]
            foreach($key in $items.Keys){
                $value = $items[$key]
                Write-Verbose "Setting key $key to value $value"

                $FinalPath = if($path.Contains(":")){$path}else{"Registry::$path"}
                $FinalName = $key
                $FinalType, $FinalValue = switch -wildcard ($value){
                    "dword:*" {
                        "dword", $value.Substring(6)
                    }
                    "qword:*" {
                        "qword", $value.Substring(6)
                    }
                    "binary:*" {
                        "binary", $value.Substring(6)
                    }
                    Default{
                        "String", $value
                    }
                }

                Write-Verbose "Final path: $FinalPath, Final name $FinalName, Final value $FinalValue, Final type $FinalType"
                if($FinalValue -eq "-"){
                    Write-Verbose "Removing because of final value $FinalValue"
                    Remove-ItemProperty -Path $FinalPath -Name $FinalName
                }
                elseif(Get-ItemProperty -Path $FinalPath -Name $FinalName -ErrorAction SilentlyContinue){
                    Write-Verbose "Changing value: Final path: $FinalPath, Final name $FinalName, Final value $FinalValue, Final type $FinalType"
                    Set-ItemProperty -Path $FinalPath -Name $FinalName -Value $FinalValue
                }
                else{
                    Write-Verbose "New value: Final path: $FinalPath, Final name $FinalName, Final value $FinalValue, Final type $FinalType"
                    if(-not (Test-Path $FinalPath)){
                        New-Item -Path $FinalPath -ItemType Directory -Force
                    }
                    New-ItemProperty -Path $FinalPath -Name $FinalName -Value $FinalValue -PropertyType $FinalType
                }
            }
        }
    }

    Write-Host "Done loading registry" -ForegroundColor $ProgressColor
}

function Setup-Hosts(){
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [String[]] $Hosts,

        [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
        [String[]] $FromURL
    )
    Write-Host "Setting up hosts file" -ForegroundColor $ProgressColor

    if($FromURL){
        Write-Verbose "Adding hosts from url from parameter"
        foreach($Line in $FromURL){
            Write-Verbose "Loading hosts from $Line"
            Add-Content -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Value (Invoke-WebRequest -URI $Line -UseBasicParsing).Content
            Write-Verbose "Done loading hosts from $Line"
        }
        Write-Verbose "Done adding hosts from url from parameter"
    }
    else{
        Write-Verbose "No from-url parameter found"
    }

    if($Hosts){
        Write-Verbose "Adding hosts from parameter"
        Add-Content -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Value $Hosts
        Write-Verbose "Done adding hosts from parameter"
    }


    Write-Host "Done setting up hosts file" -ForegroundColor $ProgressColor
}

function Remove-Bloatware(){
    [CmdletBinding()]
    param(
        [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
        [String[]] $Bloatware
    )
    Write-Host "Removing bloatware" -ForegroundColor $ProgressColor

    if($Bloatware){
        Write-Verbose "Removing bloatware from parameter"
        foreach($AppxPackage in $Bloatware){
            Write-Verbose "Removing $AppxPackage"
            Get-AppxPackage $AppxPackage | Remove-AppxPackage
            Write-Verbose "Done removing $AppxPackage"
        }
        Write-Verbose "Done removing bloatware from parameter"
    }

    Write-Host "Done removing bloatware" -ForegroundColor $ProgressColor
}

function Install-Programs(){
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [String[]] $FromPath,

        [Parameter(Position = 1)]
        [String[]] $FromURL
    )
    Write-Host "Installing programs" -ForegroundColor $ProgressColor

    #From path
    if($FromPath){
        foreach($ExeFile in $FromPath){
            Write-Verbose "Installing $ExeFile from file"
            Start-Process -FilePath "$ExeFile" -ArgumentList "/S"
            Write-Verbose "Done installing $ExeFile from file"
        }
    }

    #From URL
    if($FromURL){
        Write-Verbose "Installing from url"
        foreach($URL in $FromURL){
            Write-Verbose "Installing $URL from url"
            $Index++
            (New-Object System.Net.WebClient).DownloadFile($URL, "$($Env:TEMP)\$Index.exe")
            Start-Process -FilePath "$($Env:TEMP)\$Index.exe" -ArgumentList "/S" -Wait | Out-Null
            Remove-Item "$($Env:TEMP)\$Index.exe" -Force -ErrorAction "silentlycontinue"
            Write-Verbose "Done installing $URL from url"
        }
        Write-Verbose "Done installing from url"
    }

    Write-Host "Done installing programs" -ForegroundColor $ProgressColor
}

function Install-Choco(){
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [String[]] $Packages,
        [Parameter(Position = 1)]
        [HashTable] $Sources
    )
    Write-Host "Installing programs from Chocolatey" -ForegroundColor $ProgressColor

    #Installing Chocolatey
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
        #Setting up Chocolatey repositories
        choco feature enable -n allowGlobalConfirmation
        if($Sources){
            Write-Verbose "Removing default repository and loading new repositories from file"
            choco source remove -n=chocolatey
            foreach($Source in $Sources.Keys){
                $Splatter = $Sources[$Source]
                choco source add --name $Source @Splatter
            }
            Write-Verbose "Done removing default repository and loading new repositories from file"
        }
        #Installing from Chocolatey
        Write-Verbose "Installing from chocolatey"
        foreach($Install in $Packages){
            Write-Verbose "Installing $Install from chocolatey"
            choco install $Install --limit-output #--ignore-checksum
            choco pin add -n="$Install"
            Write-Verbose "Done installing $Install from chocolatey"
        }
        Write-Verbose "Done installing from chocolatey"
    }
    else{
        Write-Verbose "Chocolatey not installed or requires a restart after install, not installing any packages"
    }

    Write-Host "Done installing programs from Chocolatey" -ForegroundColor $ProgressColor
}

function Install-Winget(){
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [String[]] $Packages
    )
    Write-Host "Installing from winget" -ForegroundColor $ProgressColor

    if(!(Get-Command "winget" -errorAction SilentlyContinue)){
        Write-Verbose "Installing winget"
        if(Start-Process "ms-appinstaller:?source=https://aka.ms/getwinget" -ErrorAction SilentlyContinue | Wait-Process -Timeout 120 -ErrorAction SilentlyContinue){
            Write-Verbose "Done installing winget"
        }
        else{
            Write-Verbose "Timout while installing winget, skipping..."
        }
    }
    if(Get-Command "winget" -errorAction SilentlyContinue){
        Write-Verbose "Installing from winget"
        foreach($Install in $Packages){
            Write-Verbose "Installing $Install from winget"
            winget install $Install
            Write-Verbose "Done installing $Install from winget"
        }
        Write-Verbose "Done installing from winget"
    }
    else{
        Write-Verbose "Winget not installed, not installing packages"
    }

    Write-Host "Done installing from winget" -ForegroundColor $ProgressColor
}

function Setup-FileAssociations(){
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ParameterSetName = 'IniContent', ValueFromPipeline = $true)]
        [Hashtable] $IniContent
    )
    Write-Host "Setting up file associations" -ForegroundColor $ProgressColor

    foreach($Extension in $IniContent["associations"].Keys){
        $File = $IniContent["associations"][$Extension]
        Write-Verbose "Creating association $File for file type $Extension"
        Register-FTA $File $Extension
        Write-Verbose "Done creating association $File for file type $Extension"
    }

    Write-Host "Done setting up file associations" -ForegroundColor $ProgressColor
}

function Set-OptionalFeatures(){
    [CmdletBinding()]
    param(
        [Parameter(Position = 1, ParameterSetName = "IniContent")]
        [Hashtable] $IniContent
    )
    Write-Host "Setting optional features"

    foreach($Feature in $IniContent["OptionalFeatures"].Keys){
        Write-Verbose "Feature $Feature with targetstate $($IniContent["OptionalFeatures"][$Feature]) and current state $((Get-WindowsOptionalFeature -FeatureName $Feature -Online).State)"
        if($IniContent["OptionalFeatures"][$Feature] -eq "Enable"){
            Get-WindowsOptionalFeature -FeatureName $Feature -Online | Where-Object {$_.state -eq "Disabled"} | Enable-WindowsOptionalFeature -Online -NoRestart
        }
        else{
            Get-WindowsOptionalFeature -FeatureName $Feature -Online | Where-Object {$_.state -eq "Enabled"} | Disable-WindowsOptionalFeature -Online -NoRestart
        }
        Write-Verbose "Done with feature $Feature with new state $((Get-WindowsOptionalFeature -FeatureName $Feature -Online).State)"
    }

    Write-Host "Done setting optional features"
}


function Start-Setup(){
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [String] $Configuration = "default"
    )
    Start-Transcript "$Home\Desktop\$(Get-Date -Format "yyyy_MM_dd_HH_mm")_setup.transcript"

    if(Test-Path ".\$Configuration\"){
        #Requirements
        "PsIni", "Recycle", "PSHelperTools" | ForEach-Object {
            if(!(Get-InstalledModule $_ -ErrorAction "SilentlyContinue")){
                Write-Verbose "Installing required module $_"
                Install-Module $_ -Force -ErrorAction "Stop" -Confirm
                Import-Module $_ -Force -ErrorAction "Stop"
            }
        }
        Write-Host "Creating Windows Checkpoint" -ForegroundColor $ProgressColor
        Checkpoint-Computer -Description "Before $($MyInvocation.MyCommand) at $(Get-Date)"
        Read-Host "Checkpoint created. Press enter to continue" -ForegroundColor $ProgressColor

        Write-Host "Stopping Windows update service" -ForegroundColor $ProgressColor
        net stop wuauserv | Write-Host
        Read-Host "Windows update service stopped. Press enter to continue" -ForegroundColor $ProgressColor


        if(Test-Path ".\$Configuration\scripts\prepend.ps1"){
            & ".\$Configuration\scripts\prepend.ps1"
        }
        Setup-Powershell `
            -Modules (Get-Content ".\$Configuration\powershell\module.txt") `
            -PackageProviders (Get-Content ".\$Configuration\powershell\packageprovider.txt")
        Setup-Network `
            -Interfaces (Get-IniContent ".\$Configuration\settings\interfaces.ini" -IgnoreComments) `
            -DNSServers (Get-IniContent ".\$Configuration\settings\network.ini" -IgnoreComments)
        Setup-Partitions `
            -IniContent (Get-IniContent -FilePath ".\$Configuration\settings\partitions.ini" -IgnoreComments)
        Create-Symlinks `
            -IniContent (Get-IniContent -FilePath ".\$Configuration\settings\symlinks.ini" -IgnoreComments)
        Load-Registry `
            -RegistryData (Get-IniContent -FilePath ".\$Configuration\settings\registry.reg" -IgnoreComments)
        Load-Registry `
            -RegistryData (Get-IniContent -FilePath ".\$Configuration\settings\registry.ini" -IgnoreComments)
        Setup-Hosts `
            -Hosts (Get-Content ".\$Configuration\hosts\from-file.txt") `
            -FromURL (Get-Content -Path ".\$Configuration\hosts\from-url.txt" | Where-Object {$_ -notlike ";*"})
        Remove-Bloatware `
            -Bloatware (Get-Content ".\$Configuration\install\remove-bloatware.txt" | Where-Object {$_ -notlike ";*"})
        Install-Programs `
            -FromPath (Get-Childitem ".\$Configuration\install\*.exe" -Recurse) `
            -FromURL (Get-Content ".\$Configuration\install\from-url.txt" | Where-Object {$_ -notlike ";*"})
        Install-Choco `
            -Packages (Get-Content ".\$Configuration\install\from-chocolatey.txt" | Where-Object {$_ -notlike ";*"}) `
            -Sources (Get-IniContent ".\$Configuration\install\chocolatey-repository.ini" -IgnoreComments)
        Install-Winget `
            -Packages (Get-Content ".\$Configuration\install\from-winget.txt" | Where-Object {$_ -notlike ";*"})
        Setup-FileAssociations `
            -IniContent (Get-IniContent -FilePath ".\$Configuration\settings\associations.ini" -IgnoreComments)
        Set-OptionalFeatures `
            -IniContent (Get-IniContent -FilePath ".\$Configuration\settings\optionalfeatures.ini" -IgnoreComments)
        if(Test-Path ".\$Configuration\scripts\append.ps1"){
            & ".\$Configuration\scripts\append.ps1"
        }


        Write-Host "Creating Windows Checkpoint" -ForegroundColor $ProgressColor
        Checkpoint-Computer -Description "After Start-Setup at $(Get-Date)"
        Read-Host "Checkpoint created. Press enter to continue" -ForegroundColor $ProgressColor

        Write-Host "Starting Windows update service" -ForegroundColor $ProgressColor
        net start wuauserv | Write-Host
        Write-Host "Windows update service started. Press enter to continue" -ForegroundColor $ProgressColor
    }
    else{
        Write-Host "No Configuration $Configuration found, terminating execution." -ForegroundColor $ProgressColor
    }

    Stop-Transcript
}

if($Configuration -and $MyInvocation.InvocationName -ne "."){
    Write-Host "Invocation: $($MyInvocation.InvocationName)"
    Start-Setup $Configuration -ErrorAction "Stop"
}