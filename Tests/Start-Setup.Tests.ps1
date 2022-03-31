Install-Module -Name Pester -Force -Confirm:$false

BeforeAll {
    . .\setup.ps1
    Start-Setup -Group "test"
}

Describe "Start-Setup"{
    #Test hosts
        #From file
            It "Imported hosts from file successfully"{
                Select-String -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Pattern "fritz.box" | Should -Be $true
            }
        #From url
            It "Imported hosts from url successfully"{
                Select-String -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Pattern "Smart TV list" | Should -Be $true
            }
    #Test install
        #Choco repository
            #ToDo is there a way to check for repository?
        #From chocolatey
            It "Successfully installed Steam from chocolatey"{
                Test-Path "C:\Program Files (x86)\Steam" | Should -Be $true
            }
            It "Successfully installed git from chocolatey"{
                Test-Path "C:\Program Files\Git" | Should -Be $true
            }
        #From url
            It "Successfully installed chromium from url"{
                Test-Path "C:\Program Files\Chromium" | Should -Be $true
            }
        #From winget
            It "Successfully installed PuTTY from winget"{
                Test-Path "C:\Program Files\PuTTY" | Should -Be $true
            }
            It "Successfully installed WinRAR from winget"{
                Test-Path "C:\Program Files\WinRAR" | Should -Be $true
            }
        #Powershell module
            It "Successfully installed package provider NuGet"{
                Get-InstalledModule *NuGet* | Should -Be $true
            }
        #Powershell package-provider
            It "Successfully installed package provider NuGet"{
                Get-PackageProvider *NuGet* | Should -Be $true
            }
        #Remove bloatware
            It "Successfully removed bloatware *candy*"{
                Get-PackageProvider *candy* | Should -Be $true
            }
            It "Successfully removed bloatware *king*"{
                Get-PackageProvider *king* | Should -Be $true
            }
            It "Successfully removed bloatware *xing*"{
                Get-PackageProvider *xing* | Should -Be $true
            }
    #Test quickaccess
        #ToDo is there a way to check quickaccess items?
    #Test scheduled Tasks
        It "Successfully imported scheduled task"{
            Get-ScheduledTask *MicrosoftEdgeUpdateTaskMachineCore* | Should -Be $true
        }
    #Test scripts
        #Prepend
            It "Executed prepend script"{
                $ExecutedPrepend | Should -Be $true
            }
        #Append
            It "Executed append script"{
                $ExecutedAppend | Should -Be $true
            }
    #Test settings
        #ToDo GPEDIT + partitions
        #Registry
            It "Successfully import registry keys"{
                Get-ItemPropertyValue -Path "HKCU:\Control Panel\Desktop" -Name "JPEGImportQuality" | Should -Be $true
            }
        #Settings
            #Optionalfeatures
                It "Successfully enabled optional feature DirectPlay"{
                    Get-WindowsOptionalFeature -FeatureName "DirectPlay" -Online | Where-Object {$_.state -eq "Enabled"} | Should -Be $true
                }
                It "Successfully enabled optional feature TelnetClient"{
                    Get-WindowsOptionalFeature -FeatureName "TelnetClient" -Online | Where-Object {$_.state -eq "Enabled"} | Should -Be $true
                }
            #Symlinks
                It "Successfully created steam config symlink"{
                    Test-Symlink "C:\Program Files (x86)\Steam\config" | Should -Be $true
                }
            #File associations
                #ToDo is there a way to check file associations?
}