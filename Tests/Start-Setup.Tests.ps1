

BeforeAll {
    $TestGroup = "Tests\testGroup"
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
            $DebugPreference = "continue"
            Setup-Powershell -Group $TestGroup
            $DebugPreference = "silentlycontinue"
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
#            $DebugPreference = "continue"
#            Setup-Partitions -Group $TestGroup
#            $DebugPreference = "silentlycontinue"
#        }
#        #ToDo
#    }

    Context "Load-Registry"{
        BeforeAll{
            $DebugPreference = "continue"
            Load-Registry -Group $TestGroup
            $DebugPreference = "silentlycontinue"
        }
        It "Import registry keys"{
            Get-ItemPropertyValue -Path "HKCU:\Control Panel\Desktop" -Name "JPEGImportQuality" | Should -Be 100
        }
    }

    Context "Set-OptionalFeatures"{
        BeforeAll{
            $DebugPreference = "continue"
            Set-OptionalFeatures -Features $IniContent["optionalfeatures"]
            $DebugPreference = "silentlycontinue"
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
            $DebugPreference = "continue"
            Import-ScheduledTasks -Group $TestGroup
            $DebugPreference = "silentlycontinue"
        }
        It "Import scheduled tasks"{
            Get-ScheduledTask *MicrosoftEdgeUpdateTaskMachineCore* | Should -Be $true
        }
    }

#    Context "Import-GPO"{
#        BeforeAll{
#            $DebugPreference = "continue"
#            Import-GPO -Group $TestGroup
#            $DebugPreference = "silentlycontinue"
#        }
#        #ToDo
#    }

    Context "Create-Symlinks"{
        BeforeAll{
            $DebugPreference = "continue"
            Create-Symlinks -Group $TestGroup
            $DebugPreference = "silentlycontinue"
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
#            $DebugPreference = "continue"
#            Setup-FileAssociations -Associations $IniContent["associations"]
#            $DebugPreference = "silentlycontinue"
#        }
#        #ToDo Test for Setup-FileAssociations
#    }

    Context "Setup-Hosts"{
        BeforeAll{
            $DebugPreference = "continue"
            Setup-Hosts -Group $TestGroup
            $DebugPreference = "silentlycontinue"
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
#            $DebugPreference = "continue"
#            Setup-Taskbar -Group $TestGroup
#            $DebugPreference = "silentlycontinue"
#        }
#        #ToDo Test for Setup-Taskbar
#    }

#    Context "Setup-Quickaccess"{
#        BeforeAll{
#            $DebugPreference = "continue"
#            Setup-Quickaccess -Group $TestGroup
#            $DebugPreference = "silentlycontinue"
#        }
#        #ToDo Test for Setup-Quickaccess
#    }

    Context "Remove-Bloatware"{
        BeforeAll{
            $DebugPreference = "continue"
            Remove-Bloatware -Group $TestGroup
            $DebugPreference = "silentlycontinue"
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
            $DebugPreference = "continue"
            Install-Programs -Group $TestGroup
            $DebugPreference = "silentlycontinue"
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