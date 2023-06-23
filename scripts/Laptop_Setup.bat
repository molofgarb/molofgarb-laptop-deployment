:: Used to set up Latitude 5320. Please clone using latest image before running this script.
:: This script needs a file "secrets.txt", the KMS installer, and "Laptop_Setup_secret.bat" in the same directory

@echo off
cd %~dp0

set "header=cls & echo =============================================================================== & echo Latitude 5320 Setup Script & echo =============================================================================== & echo."
set "pause_until_done=echo Press any key to continue. . . & pause > nul"


:: ===== CONNECT TO INTERNET ==================================================
:Check_Internet
%header%
echo Please connect to the internet (Wi-Fi or Ethernet).
%pause_until_done%

set "testhost=8.8.8.8"

ping -n 1 "%testhost%" | findstr /r /c:"[0-9] *ms"

if %errorlevel% == 0 (
    %header%
    echo The connection is up.
    %pause_until_done%
    goto Check_Internet_Up
) else (
    %header%
    echo The connection is down. (or you're on VPN; please disconnect from VPN^)
    %pause_until_done%
    goto Check_Internet
)
:Check_Internet_Up

%header%
echo Synchronizing time. . .

echo.
net start w32time
w32tm /resync
echo.

echo Time sync complete.
%pause_until_done%


:: ===== UPDATES ==============================================================
:Start_Windows_Update

%header%
echo This script will open the Windows Update panel to start a Windows Update check.
%pause_until_done%

start "" C:\Windows\System32\control.exe /name Microsoft.WindowsUpdate

%header%
echo Please install Windows updates.
%pause_until_done%

:Start_Dell_Update
:: NOTE: this runs in the background
%header%
echo This script will open a Dell Command ^| Update CLI process. It will run in the background.
%pause_until_done%
start "" "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" /applyUpdates -reboot=disable -autoSuspendBitLocker=enable -forceupdate=enable

%header%
echo This script will open Chrome and Firefox to start an update check.
%pause_until_done%

:Open_Browser_Update
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe"
start "" "C:\Program Files\Mozilla Firefox\firefox.exe"

%header%
echo Please manually update Chrome and Firefox.
%pause_until_done%

%header%
echo This script will open Zoom to start an update check.
%pause_until_done%

start "" "C:\Program Files\Zoom\bin\Zoom.exe"

%header%
echo Please make sure that Zoom is updated to the latest version.
%pause_until_done%


:: ===== COMPUTER NAME ========================================================
:Start_compname
:: Get Service Tag
wmic bios get serialnumber | findstr /v "SerialNumber" > temp.txt

set /p ser_tag= <temp.txt
set ser_tag=%ser_tag: =%

del temp.txt


:: Get Prefix (from user)
set prefix=XXX

%header%
echo The prefix (e.g. REG) is: 

set /p prefix=
echo:

:: Set New Name
set new_name=%prefix%-%ser_tag%

cmd /c "wmic computersystem where name='%computername%' call rename name='%new_name%'"

%header%
echo The new computer name is: %new_name%
%pause_until_done%


:: ===== ACCOUNT MANAGEMENT ===================================================
call Laptop_Setup_secret.bat
if not %errorlevel% == 0 (
    goto Start_compname
)

:: ===== MICROSOFT OFFICE =====================================================
for /f %%i IN (secrets.txt) DO if not defined line set "result=%%i" & goto Start_KMS_done
:Start_KMS_done
start /b %result%

%header%
echo Connect to VPN.
%pause_until_done%
:Start_Office_Wait
%header%
echo We will wait at least 5 minutes for Microsoft Office activation. . .
timeout /t 300

start "" "C:\Program Files\Microsoft Office\Office16\WINWORD.EXE"

%header%
echo Is Microsoft Office activated? (y/N) (default:n)
set "answer=n"
set /p "answer="

if /I "%answer%" == "n" (
    goto Start_Office_Wait
) 

%header%
wmic path softwarelicensingservice get OA3xOriginalProductKey | findstr /v OA3xOriginalProductKey > %temp%\temp.txt
set /p key=< %temp%\temp.txt
del %temp%\temp.txt

echo Windows 10 Pro Product Key: %key%

slmgr.vbs /ipk %key%

echo:
echo Windows 10 Pro activated!
%pause_until_done%


:: ===== BITLOCKER AND BIOS PASSWORD ==========================================
%header%
echo Please set up BitLocker, BIOS password, and MAC address pass-through according to the setup instructions document. 
echo The script will end now.
echo.
echo Press any key to exit. . . & pause > nul


:: Credits
:: https://stackoverflow.com/questions/1788473/while-loop-in-batch
:: https://stackoverflow.com/questions/9329749/batch-errorlevel-ping-response
:: https://www.dell.com/support/manuals/en-us/command-update/dellcommandupdate_rg/dell-command-|-update-cli-commands?guid=guid-92619086-5f7c-4a05-bce2-0d560c15e8ed&lang=en-us