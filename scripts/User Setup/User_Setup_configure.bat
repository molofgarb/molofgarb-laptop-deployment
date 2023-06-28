:: Run this as an user to configure parts of the environment. This should be run after User_Setup_create.bat
:: If you have any questions or issues, please contact the author of this script.

@echo off
cd /d "%~dp0"

:: MACROS
set "header=cls & echo =============================================================================== & echo User Setup Script & echo =============================================================================== & echo."
set "pause_until_done=echo Press any key to continue. . . & pause > nul"
set "defaults=User_Setup_defaultappassoc.xml"

:: ===== CONFIGURE DEFAULT PROGRAMS ===========================================

%header%
echo Setting default programs. . .
dism /online /Import-DefaultAppAssociations:"User_Setup_defaultappassoc.xml"
%pause_until_done%

:: ===== CONFIGURE PROGRAMS ===================================================

:Firefox
%header%
echo This script will open Firefox. Once it opens, please disable it from asking about being the default browser.
%pause_until_done%

start "" "C:\Program Files\Mozilla Firefox\firefox.exe"
echo Please wait 5 seconds. . .
echo.
timeout /t 5 /nobreak
taskkill /im firefox.exe /f
start "" "C:\Program Files\Mozilla Firefox\firefox.exe"

%header%
echo Please tell Firefox not to ask about being set as the default browser.
%pause_until_done%


:Edge
%header%
echo This script will open Edge. Once it opens, select the option that opens the browser without sign-in and close.
%pause_until_done%

start "" "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

%header%
echo Please configure Edge.
%pause_until_done%


:Word
%header%
echo This script will open Microsoft Word. Please set Word to install updates only.
%pause_until_done%

start "" "C:\Program Files\Microsoft Office\Office16\WINWORD.EXE"

%header%
echo Please set Word to install updates only.
%pause_until_done%


:OneDrive
%header%
echo Please open the hidden items menu in the taskbar, right click on OneDrive, click on settings, and then disable OneDrive from automatically starting.
%pause_until_done%


:WindowSecurity
%header%
echo Please open the hidden items menu in the taskbar, open the Windows Security Panel, and dismiss the security concerns.
%pause_until_done%

:: ===== SETTINGS ===================================================

%header%
echo Using the start menu, go to the "Sign-in options" settings panel and disable the setting below:
echo.
echo Use my sign-in info to automatically finish setting up my device after an update or restart
echo.
%pause_until_done%

:: ===== TASKBAR ===================================================

%header%
echo Configure the taskbar as follows:
echo 1. Set the search bar to be hidden
echo 2. Set Cortana to be hidden
echo 3. Remove all shortcuts on the task bar except for the File Explorer shortcuts
echo 4. Set the notifications icon (bottom right) to not show app icons and not show number of new notifications.


%header%
echo The script will end now.
echo.
echo Press any key to exit. . . & pause > nul