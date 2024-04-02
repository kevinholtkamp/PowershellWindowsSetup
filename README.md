# PowershellWindowsSetup
I decided to make a public version of my Powershell script for setting up Windows after installation.
I decided to do this so that other people can benefit from this, and also because I wanted to learn more about how git/GitHub works in respect to Pull requests, forks and other things.

The script is set up in such a way where you edit/add files in the subfolders, or edit the setup.ini instead of editing the script directly.
This way you can set up your files and have them work with different versions of the script.
Additionally, I try to create the script in a way where you can run it again at a later date without breaking anything.

## How to use
- Change the values of the files in the `default`-folder according to your requirements and the specifications defined in the [Configuration files section](#Configuration-files), or delete files you do not need
- Alternatively, create a new folder in the root directory of the project for every Configuration you need and create all the files in the same format as in the `default`-folder
- If you want to use the `default` configuration, you can just right-click the script file and "Run with Powershell", or call the script without parameters
- If you want to use a different configuration, open a powershell console in the root directory of the project, load the setup.ps1 file with the Configuration-Parameter set to your Configuration
```Powershell      
    .\Run-Setup.ps1 -Configuration "default"
```
## Configuration files
### .\hosts\
- `from-file.txt` plain text file where each line represents one entry in the windows hosts file format
- `from-url.txt` plain text file where each line represents a url to a file in the windows hosts file format
### .\install\
- `chocolatey-repository.ini` ini file where every section corresponds to a chocolatey repository with the keys being the parameters used to create the repository via powershell "splatter"
- `from-chocolatey.txt` plain text file where each line represents the name of a chocolatey package
- `from-url.txt` plain text file where each line represents a url to an executable file
- `from-winget.txt` plain text file where each line represents the name of a winget package
- `remove-bloatware.txt` plain text file where each line represents the name of an AppxPackage
### .\powershell\
- `module.txt` plain text file where each line represents the name of a powershell module
- `packageprovider.txt` plain text file where each line represents the name of a powershell package-provider
### .\scripts\
- `append.ps1` script file that gets executed after the main script
- `prepend.ps1` script file that gets executed before the main script
### .\settings\
- `associations.ini` ini file containing file type associations to be set
- `partitions.ini` ini file where each key represents the serial number of a disk and every entry contains the target drive letter for a partition index
- `registry.reg` reg file containing registry keys in the Windows Registry Editor Version 5.00 format
- `symlinks.ini` ini file containing symlinks to be set

## Create a new configuration
To create a new configuration you can either create it manually or launch the `Create-Configuration` script. You will be prompted for everything needed in a configuration.
Afterwards, the configuration will be saved in the correct format in a new folder with the configuration name