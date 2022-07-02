Xcopy /E /I C:\Users\WDAGUtilityAccount\PowershellWindowsSetup C:\Users\WDAGUtilityAccount\Desktop\PowershellWindowsSetup
explorer.exe C:\Users\WDAGUtilityAccount\Desktop\PowershellWindowsSetup
powershell.exe -command "Set-Executionpolicy Remotesigned -Force"
cd C:\Users\WDAGUtilityAccount\Desktop\PowershellWindowsSetup
start powershell.exe -NoExit -NoLogo -WindowStyle "Maximized" -File "C:\Users\WDAGUtilityAccount\Desktop\PowershellWindowsSetup\Tests\RunTests.ps1"