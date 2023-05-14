#Requires -Version 6.2
if(!(Get-InstalledModule "PSHelperTools" -ErrorAction SilentlyContinue -MinimumVersion "0.0.5")){
    Install-Module PSHelperTools -RequiredVersion "0.0.5" -Force -SkipPublisherCheck -ErrorAction "stop"
    Import-Module PSHelperTools -RequiredVersion "0.0.5"
}

function Prompt($Prompt){
    do{
        Write-Host $Prompt -ForegroundColor Blue -NoNewline
        $Input = Read-Host
    } while(-Not $Input)
    return $Input
}
function PromptN($Item){
    $Return = [System.Collections.ArrayList]@()
    Write-Host "Enter any number of $Item, just press enter to exit: " -ForegroundColor Blue -NoNewline
    $Input = Read-Host
    while($Input -ne ""){
        $Return.Add($Input) | Out-Null
        Write-Host "Another one: " -ForegroundColor Blue -NoNewline
        $Input = Read-Host
    }
    return $Return
}
function PromptYesNo($Prompt){
    Write-Host "$Prompt (yes/no): " -ForegroundColor Blue -NoNewline
    while($true){
        $Answer = Read-Host
        $Answer = $Answer.ToLower()
        if($Answer -eq "yes" -or $Answer -eq "y"){
            return $true
        }
        elseif ($Answer -eq "no" -or $Answer -eq "n"){
            return $false
        }
        Write-Host "Please enter a valid answer: " -ForegroundColor Red -NoNewline
    }
}



#Configuration name
do{
    $ConfigurationName = Prompt "Enter configuration name: "
    if(Test-Path ".\$ConfigurationName"){
        Write-Host "Configuration exists already, please enter a different name" -ForegroundColor Red
    }
}while(Test-Path ".\$ConfigurationName");


#hosts
    $Hosts = @{}
    #from file
    if(PromptYesNo "Do you want to add host-file entries from your current installation?"){
        Write-Host "Reading host file entries from current installation" -ForegroundColor Green
        $Hosts["FromFile"] = Get-Content "$($Env:WinDir)\system32\Drivers\etc\hosts" | ForEach-Object {$_.Split("#")[0].Trim()} | Where-Object {!$_.Equals("")}
    }
    #Manual entries for use in from file
    $Hosts["FromFile"].Add((PromptN "host file entries (Format: <IP> <Domain>)"))
    #from url
    $Hosts["FromURL"] = PromptN "URLs with host file entries"

#install
    $Install = @{}
    #exe
    Write-Host "If you want to install any exe files, simply add them to the .\$ConfigurationName\install\ directory" -ForegroundColor Yellow
    #from url
    $Install["FromURL"] = PromptN "URLs for installation"
    #choco
    if(Get-Command "choco" -ErrorAction SilentlyContinue){
        if(PromptYesNo "Do you want to read all installed chocolatey packages?"){
            Write-Host "Reading installed choco packages from current installation" -ForegroundColor Green
            $Install["FromChocolatey"] = (choco list -localonly --limitoutput | ForEach-Object {$_.Split("|")[0]})
        }
    }
    #winget
    if(Get-Command "winget" -ErrorAction SilentlyContinue){
        if(PromptYesNo "Do you want to read all installed winget packages?"){
            Write-Host "Reading installed winget packages from current installation" -ForegroundColor Green
            & winget export ".\from-winget.json" | Out-Null
            $Install["FromWinget"] = Get-Content ".\from-winget.json" | Where-Object {$_ -like '*PackageIdentifier*'} | ForEach-Object {$_.Split(":")[1].Replace('"','').Trim()}
            Remove-Item ".\from-winget.json"
        }
    }
    #Remove bloatware
    $Install["RemoveBloatware"] = PromptN "bloatwares to remove (wildcards permitted)"

#powershell
    $Powershell = @{}
    #module
    if(PromptYesNo "Do you want to read all installed powershell modules?"){
        Write-Host "Reading installed powershell modules from current installation" -ForegroundColor Green
        $Powershell["Module"] = Get-InstalledModule | ForEach-Object {$_.Name}
    }
    #packageprovider
    if(PromptYesNo "Do you want to read all installed powershell package providers?"){
        Write-Host "Reading installed package providers from current installation" -ForegroundColor Green
        $Powershell["PackageProvider"] = Get-PackageProvider | ForEach-Object {$_.Name}
    }

#scripts
    #prepend
    #append

#settings
    $Settings = @{}
    #associations
    $Settings["FileAssociations"] = PromptN "file associations (format: .csv=C:\windows\system32\notepad.exe)"
    #partitions
    if(PromptYesNo "Do you want to read the partition letters from the current installation?"){
        Write-Host "Reading partition letters from current installation" -ForegroundColor Green
        $Settings["Partitions"] = [System.Collections.ArrayList]@()
        Get-Disk | `
            ForEach-Object {`
                $Settings["Partitions"].Add("[$($_.SerialNumber)]") | Out-Null; `
                Get-Partition $_.Number | `
                    ForEach-Object {`
                        if($_.DriveLetter -and $_.DriveLetter -ne "C"){
                            $Settings["Partitions"].Add("$($_.PartitionNumber)=$($_.DriveLetter)") | Out-Null
                        }
                    }
            }
    }
    #registry
    #symlinks ToDo angucken
    if(PromptYesNo "Do you want to read symlinks from current installation?"){
        $FoldersToSearch = PromptN "folders to search for symlinks (Enter none for defaults)"
        if(!$FoldersToSearch){
            $FoldersToSearch = @("$env:USERPROFILE\AppData", "D:\", "E:\", "C:\Users\Public\Documents\")
        }
        Write-Host "Finding symlinks in the following paths: $FoldersToSearch" -ForegroundColor Green
        $Settings["Symlinks"] = [System.Collections.ArrayList]@()
        $Links = @{}
        foreach($Folder in $FoldersToSearch){
            $LLinks = Get-ChildItem $Folder -Recurse -ErrorAction SilentlyContinue | `
            Where-Object {Get-SymlinkTarget $_.FullName} | `
            ForEach-Object -Begin {
                $Out = @{}
            } -Process {
                $Out.Add($_.FullName, (Get-SymlinkTarget $_.FullName)) | Out-Null
            } -End {
                $Out
            }
            $Links += $LLinks
        }
        $UsedDriveLetters = $Links.Values | ForEach-Object {
            (Get-Item $_ -ErrorAction SilentlyContinue).Root
        } | Select-Object -Unique
        foreach($Letter in $UsedDriveLetters){
            $Settings["Symlinks"].Add("[$($Letter.ToString().TrimEnd("\"))]") | Out-Null
            $Temp = [System.Collections.ArrayList]@()
            foreach($Link in $Links.Keys){
                $Value = $Links[$Link]
                if($Value.StartsWith($Letter)){
                    $Temp.Add("$($Value.ToString().Substring($Letter.Length + 2))=$Link") | Out-Null
                }
            }
            $Temp | Sort-Object | ForEach-Object {
                $Settings["Symlinks"].Add($_) | Out-Null
            }
        }
    }



Write-Host "Generated the following configuration:" -ForegroundColor Blue
Write-Host "Hosts: $($Hosts.ToString())"
Write-Host "Install: $($Install.ToString())"
Write-Host "Powershell: $($Powershell.ToString())"
Write-Host "Settings: $($Settings.ToString())"


if(PromptYesNo "Want to save this configuration?"){
    New-Item ".\$ConfigurationName" -ItemType Directory | Out-Null
    Push-Location ".\$ConfigurationName"

    #hosts
    if($Hosts){
        New-Item ".\hosts" -ItemType Directory -Force | Out-Null
    }
    if($Hosts["FromFile"]){
        New-Item ".\hosts\from-file.txt" -ItemType File | Out-Null
        Set-Content ".\hosts\from-file.txt" $Hosts["FromFile"]
    }
    if($Hosts["FromURL"]){
        New-Item ".\hosts\from-url.txt" -ItemType File | Out-Null
        Set-Content ".\hosts\from-url.txt" $Hosts["FromURL"]
    }
    #install
    if($Install){
        New-Item ".\install" -ItemType Directory -Force | Out-Null
    }
    if($Install["FromChocolatey"]){
        New-Item ".\install\from-chocolatey.txt" -ItemType File | Out-Null
        Set-Content ".\install\from-chocolatey.txt" $Install["FromChocolatey"]
    }
    if($Install["FromWinget"]){
        New-Item ".\install\from-winget.json" -ItemType File | Out-Null
        Set-Content ".\install\from-winget.json" $Install["FromWinget"]
    }
    if($Install["FromURL"]){
        New-Item ".\install\from-url.txt" -ItemType File | Out-Null
        Set-Content ".\install\from-url.txt" $Install["FromURL"]
    }
    if($Install["RemoveBloatware"]){
        New-Item ".\install\remove-bloatware.txt" -ItemType File | Out-Null
        Set-Content ".\install\remove-bloatware.txt" $Install["RemoveBloatware"]
    }
    #powershell
    if($Powershell){
        New-Item ".\powershell" -ItemType Directory -Force | Out-Null
    }
    if($Powershell["Module"]){
        New-Item ".\powershell\module.txt" -ItemType File | Out-Null
        Set-Content ".\powershell\module.txt" $Powershell["Module"]
    }
    if($Powershell["PackageProvider"]){
        New-Item ".\powershell\packageprovider.txt" -Force | Out-Null
        Set-Content ".\powershell\packageprovider.txt" $Powershell["PackageProvider"]
    }
    #scripts
    #settings
    if($Settings){
        New-Item ".\settings" -ItemType Directory -Force | Out-Null
    }
    if($Settings["Partitions"]){
        New-Item ".\settings\partitions.ini" -ItemType File | Out-Null
        Set-Content ".\settings\partitions.ini" $Settings["Partitions"]
    }
    if($Settings["Symlinks"]){
        New-Item ".\settings\symlinks.ini" -ItemType File | Out-Null
        Set-Content ".\settings\symlinks.ini" $Settings["Symlinks"]
    }
    if($Settings["FileAssociations"]){
        New-Item ".\settings\associations.ini" -ItemType File | Out-Null
        Set-Content ".\settings\associations.ini" "[associations]"
        Add-Content ".\settings\associations.ini" $Settings["FileAssociations"]
    }

    Pop-Location
    Write-Host "Done writing configuration"
}