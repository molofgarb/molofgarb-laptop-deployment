:: Used to set up Latitude 5320. Please clone using latest image before running this script.
:: This script needs the files:
::      Laptop_Setup_secrets.txt    - a file containing KMS, BitLocker, and password information
::      <KMS installer>.msi         - an installer for the KMS for Microsoft Office activation
::      Laptop_Setup_compmgmt.bat   - a batch file with user account configurations
::      Laptop_Setup_bitlocker.bat  - a batch file with BitLocker setup commands
::
:: Templates have been provided for the two batch files that this script requires.
:: If you have any questions or issues, please contact the author of this script.

@echo off
cd /d "%~dp0"

:: MACROS
set "header=cls & echo =============================================================================== & echo Latitude 5320 Setup Script & echo =============================================================================== & echo."
set "pause_until_done=echo Press any key to continue. . . & pause > nul"
set "secrets=Laptop_Setup_secrets.txt"

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

:Syncrhonize_Time
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
%header%
echo The prefix (e.g. REG) is: 

set prefix=XXX
set /p "prefix=Prefix: "
echo:

:: Set New Name
set new_name=%prefix%-%ser_tag%

cmd /c "wmic computersystem where name='%computername%' call rename name='%new_name%'"

%header%
echo The new computer name is: %new_name%
%pause_until_done%


:: ===== ACCOUNT MANAGEMENT ===================================================

:: required variables are: header, pause_until_done, prefix
if exist Laptop_Setup_compmgmt.bat (
    call Laptop_Setup_compmgmt.bat
) else (
    %header%
    echo Please set up the user accounts in Computer Management.
    %pause_until_done%
)

if not %errorlevel% == 0 (
    goto Start_compname
)

:: ===== MICROSOFT OFFICE =====================================================

for /f %%i IN (%secrets%) DO if not defined line set "result=%%i" & goto Start_KMS_done
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
set /p "answer=Answer: "

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

:: ===== BITLOCKER ============================================================

:: required variables are: header, pause_until_done, ser_tag
if exist Laptop_Setup_bitlocker.bat (
    call Laptop_Setup_bitlocker.bat
) else (
    %header%
    echo Please set up BitLocker.
    %pause_until_done%
)

:: ===== BIOS PASSWORD AND MAC ================================================

%header%
echo Please set up BIOS password and MAC address pass-through according to the setup instructions document. 
echo The script will end now.
echo.
echo Press any key to exit. . . & pause > nul
