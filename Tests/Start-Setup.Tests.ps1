

BeforeAll {
    $TestGroup = "Tests\testGroup"
    $DebugPreference = "Continue"
    Install-Module -Name PsIni -Force -Confirm:$false
    Install-Module -Name Recycle -Force -Confirm:$false
    . .\setup.ps1
    $IniContent = Get-IniContent -FilePath ".\$TestGroup\settings\settings.ini" -IgnoreComments
    Mock -CommandName Write-Debug -MockWith {}
    Mock -CommandName Read-Host -MockWith {Write-Host $Prompt}
    Mock -CommandName Update-Help -MockWith {}
}

Describe "Start-Setup"{

    #Every function and custom script in Start-Setup is represented by its own Context in Pester
    #This excludes the code in Start-Setup like the creation of a windows checkpoint and stopping of windows update service

    Context "Prepend Script"{
        BeforeAll{
            & ".\$TestGroup\scripts\prepend_custom.ps1"
        }
        It "Prepend Script"{
            $ExecutedPrepend | Should -Be $true
        }
    }

    Context "Setup-Powershell"{
        BeforeAll{
            Setup-Powershell -Group $TestGroup
        }
        It "PackageProvider NuGet"{
            Get-PackageProvider *NuGet* | Should -Be $true
        }
        It "Module Recycle"{
            Get-InstalledModule *Recycle* | Should -Be $true
        }
    }

#    Context "Setup-Partitions"{
#        BeforeAll{
#            Setup-Partitions -Group $TestGroup
#        }
#        #ToDo
#    }

    Context "Load-Registry"{
        BeforeAll{
            Load-Registry -Group $TestGroup
        }
        It "Import registry keys"{
            Get-ItemPropertyValue -Path "HKCU:\Control Panel\Desktop" -Name "JPEGImportQuality" | Should -Be 100
        }
    }

    Context "Set-OptionalFeatures"{
        BeforeAll{
            Set-OptionalFeatures -Features $IniContent["optionalfeatures"]
        }
        It "Optional feature DirectPlay"{
            Get-WindowsOptionalFeature -FeatureName "DirectPlay" -Online | Where-Object {$_.state -eq "Enabled"} | Should -Be $true
        }
        It "Optional feature TelnetClient"{
            Get-WindowsOptionalFeature -FeatureName "TelnetClient" -Online | Where-Object {$_.state -eq "Enabled"} | Should -Be $true
        }
    }

    Context "Import-ScheduledTasks"{
        BeforeAll{
            Import-ScheduledTasks -Group $TestGroup
        }
        It "Import scheduled tasks"{
            Get-ScheduledTask *MicrosoftEdgeUpdateTaskMachineCore* | Should -Be $true
        }
    }

#    Context "Import-GPO"{
#        BeforeAll{
#            Import-GPO -Group $TestGroup
#        }
#        #ToDo
#    }

    Context "Create-Symlinks"{
        BeforeAll{
            Create-Symlinks -Group $TestGroup
        }
        It "Steam config symlink"{
            Test-Symlink "C:\Program Files (x86)\Steam\config" | Should -Be $true
        }
        It "MSI Afterburner symlink"{
            Test-Symlink "C:\Program Files (x86)\MSI Afterburner\Profiles" | Should -Be $true
        }
        It "Ubisoft game launcher symlink"{
            Test-Symlink "C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\savegames" | Should -Be $true
        }
    }

#    Context "Setup-FileAssociations"{
#        BeforeAll{
#            Setup-FileAssociations -Associations $IniContent["associations"]
#        }
#        #ToDo Test for Setup-FileAssociations
#    }

    Context "Setup-Hosts"{
        BeforeAll{
            Setup-Hosts -Group $TestGroup
        }
        It "Importing hosts from file"{
            Select-String -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Pattern "fritz.box" | Should -not -BeNullOrEmpty
        }
        It "Importing hosts from url"{
            Select-String -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Pattern "Smart TV list" | Should -not -BeNullOrEmpty
        }
    }

#    Context "Setup-Taskbar"{
#        BeforeAll{
#            Setup-Taskbar -Group $TestGroup
#        }
#        #ToDo Test for Setup-Taskbar
#    }

#    Context "Setup-Quickaccess"{
#        BeforeAll{
#            Setup-Quickaccess -Group $TestGroup
#        }
#        #ToDo Test for Setup-Quickaccess
#    }

    Context "Remove-Bloatware"{
        BeforeAll{
            Remove-Bloatware -Group $TestGroup
        }
        It "Removing bloatware *candy*"{
            Get-AppxPackage *candy* | Should -Be $null
        }
        It "Removing bloatware *king*"{
            Get-AppxPackage *king* | Should -Be $null
        }
        It "Removing bloatware *xing*"{
            Get-AppxPackage *xing* | Should -Be $null
        }
    }

    Context "Install-Programs"{
        BeforeAll{
            Install-Programs -Group $TestGroup
        }
        #ToDo Test for chocolatey Repository
        #From chocolatey
        It "Installed Steam from chocolatey"{
            "C:\Program Files (x86)\Steam" | Should -Exist
        }
        It "Installed git from chocolatey"{
            "C:\Program Files\Git" | Should -Exist
        }
        #From url
        It "Installed chromium from url"{
            "C:\Program Files\Chromium" | Should -Exist
        }
        #From winget
        It "Installed PuTTY from winget"{
            "C:\Program Files\PuTTY" | Should -Exist
        }
        It "Installed WinRAR from winget"{
            "C:\Program Files\WinRAR" | Should -Exist
        }
    }

    Context "Append Script"{
        BeforeAll{
            & ".\$TestGroup\scripts\append_custom.ps1"
        }
        It "Append Script"{
            $ExecutedAppend | Should -Be $true
        }
    }
}