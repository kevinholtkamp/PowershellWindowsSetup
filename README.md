# PowershellWindowsSetup
I decided to make a public version of my Powershell script for setting up Windows after installation.
I decided to do this so that other people can benefit from this, and also because I wanted to learn more about how git/GitHub works in respect to Pull requests, forks and other things.

The script is set up in such a way where you edit/add files in the subfolders, or edit the setup.ini instead of editing the script directly.
This way you can set up your files and have them work with different versions of the script.
Additionally, I try to create the script in a way where you can run it again at a later date without breaking anything.

## How to use
- Change the values of the files in the `default`-folder according to your requirements and the specifications defined in the [Configuration files section](#Configuration-files), or delete files you do not need
- Alternatively, create a new folder in the root directory of the project for every user Configuration you need and create all the files in the same format as in the `default`-folder
- Open a powershell console in the root directory of the project, load the setup.ps1 file and call the function `Start-Setup` with the Configuration-Parameter set to your user Configuration if you do not use the default Configuration:
```Powershell      
        . .\setup.ps1
        Start-Setup -Configuration "default"
```
## Configuration files
### .\hosts\
- `from-file.txt` plain text file where each line represents one entry in the windows hosts file format
- `from-url.txt` plain text file where each line represents a url to a file in the windows hosts file format
### .\install\
- `from-chocolatey.txt` plain text file where each line represents the name of a chocolatey package
- `from-winget.txt` plain text file where each line represents the name of a winget package
- `from-url.txt` plain text file where each line represents a url to an executable file
- `powershell-module.txt` plain text file where each line represents the name of a powershell module
- `powershell-packageprovider.txt` plain text file where each line represents the name of a powershell package-provider
- `remove-bloatware.txt` plain text file where each line represents the name of an AppxPackage
- `chocolatey-repository.ini` ini file where every section corresponds to a chocolatey repository with the keys being the parameters used to create the repository via powershell "splatter"
### .\quickaccess\
- `folders.txt` plain text file where each line represents the path to a folder
### .\scheduledTasks\
- `.\scheduledTasks\` can contain none or any number of .xml files which represent a scheduled task in the [Windows task format](http://schemas.microsoft.com/windows/2004/02/mit/task)
### .\scripts\
- `.\scripts\` can contain custom script files prepend_custom.ps1 and append_custom.ps1 which get executed before and after the other functions respectively
### .\settings\
- `gpedit.txt` text file containing a Windows registry backup in the Windows group policy backup file format
- `partitions.ini` ini file where each key represents the serial number of a disk and every entry contains the target drive letter for a partition index
- `registry.reg` reg file containing registry keys in the Windows Registry Editor Version 5.00 format
- `settings.ini` ini file containing the keys optionalFeatures, links and associations for their respective settings
- `taskbar.xml` xml file containing taskbar settings in the [Windows taskbar layout file format](https://schemas.microsoft.com/Start/2014/TaskbarLayout)