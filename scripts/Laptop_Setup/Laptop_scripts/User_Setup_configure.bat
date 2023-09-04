:: Run this as an user to configure parts of the environment. This should be run after User_Setup_create.bat
:: If you have any questions or issues, please contact the author of this script.

@echo off
setlocal EnableDelayedExpansion
color 0e

set "CURR_SCRIPT=%~nx0"
title %CURR_SCRIPT%
cd /d "%~dp0"

:: Initialize common macros
if not exist ..\lib\__common.bat ( 
    echo The dependency ..\lib\__common.bat does not exist. 
    echo This script will end now.
    echo Press any key to exit. . .
    pause >nul
    exit 1
)
call ..\lib\__common.bat init

:: Set macros from main menu if not defined (script launched directly)
if not defined NOPAUSE  ( set "NOPAUSE=disabled" )
if not defined LOCALLOG ( set "LOCALLOG=disabled" )

call:inc func_log_init "Latitude 5320 User Configuration"
call:inc func_progressbar_init "%~f0"

:: Initial checks
:: Note: each check performs one progressbar increment
call:inc func_check_admin

:: Note that %ser_tag% is set by func_log_init
call:inc func_log "START" "%~0"
call:inc func_log "INFO" "The service tag is %ser_tag%"
call:inc func_log "INFO" "The shell user is %username%"
call:inc func_log "INFO" "The current logged in user is %current_user%"

:: ===== GPUPDATE SETTING =====================================================

call:inc func_progressbar_inc "Input: Local Group Policy Update Interval"

call:inc func_log "START" "Setting script's registry update frequency"

:Registry_update_interval_input
%HEADER%
echo This script will apply multiple registry changes.
echo Updating the registry after each change will take 5-10 seconds.
echo Do you want to update the registry at the end of the script or after each change?
echo (1)    Update only at the end of the script (recommended, faster)
echo (2)    Update after each registry change

set /p "result=Please enter your preferred update interval: "
call:inc func_log "INFO" "The script update frequency input is %result%"

:: validate input 
call:reg_update_switch_%result% 2>nul
if not %errorlevel% == 0 (
    call:inc func_msg ^
        "Please enter a valid input -- the valid inputs are 1 or 2." ^
        "ERROR" "Invalid registry update interval input entered: %result%"
    goto Registry_update_interval_input
)

goto reg_update_done

:reg_update_switch_1
    set "registry_always_update=n"
    exit /b 0

:reg_update_switch_2
    set "registry_always_update=y"
    exit /b 0

:reg_update_done
call:inc func_log "INFO" "The registry update setting is: %registry_always_update%"

:: Local macro
:: If the registry is set to always update, then this macro updates the registry
:: If not, then this macro does nothing
set "REG_ALWAYS_UPDATE=if !registry_always_update! == y "
set "REG_ALWAYS_UPDATE=%REG_ALWAYS_UPDATE%( echo. & echo Updating local group policy. . . "
set "REG_ALWAYS_UPDATE=%REG_ALWAYS_UPDATE%& powershell gpupdate >nul )"

:: ===== GET USER REGISTRY ====================================================

call:inc func_log "START" "Get %current_user%'s registry hive"

reg query HKLM\SYSTEM\CurrentControlSet\Control\hivelist | findstr /c:%current_user% | findstr /c:\REGISTRY\USER | findstr /c:NTUSER.DAT > temp_userhive.txt
for /f "tokens=1" %%i in (temp_userhive.txt) do (
    set "user_hive=%%i"
    set "user_hive=!user_hive:~15!"
    set "user_hive=HKEY_USERS\!user_hive!"
)
del temp_userhive.txt

call:inc func_log "INFO" "%current_user%'s registry hive is %user_hive%"

:: ===== DEFAULT APPS =========================================================

call:inc func_progressbar_inc "Set Default Applications"

call:inc func_msg ^
    "If you ran Laptop_Setup_prep.bat on this laptop, then the default applications should already be set." ^
    "INFO" "Default applications notification" ^
    "If you did not run the prep script, then please set the default applications manually." ^
    "Chrome is the default browser and Adobe Acrobat Pro DC is default PDF reader."

:Default_programs_set
%HEADER%
echo Please confirm that the default programs have been set.
echo If you previously ran Laptop_Setup_prep.bat to completion, then the programs have been set.
echo Otherwise, please manually confirm and set the programs.
echo.
set "result="
set /p "result=Type y and press enter once you have set the default programs: "
call:inc func_check_confirmation "!result!" ^
    Default_programs_done ^
    Default_programs_set
goto !confirm_result!
:Default_programs_done

:: ===== FIREFOX ==============================================================

call:inc func_progressbar_inc "Set Firefox to Not Ask to be Default"

call:inc func_check_if_exists "%OS_DRIVE%\Program Files\Mozilla Firefox\firefox.exe"
if not %errorlevel% == 0 (
    call:inc func_log "INFO" "Firefox set not default skipped"
    goto Firefox_Skip
)

:: We set Firefox as default first and then override it with Chrome as default.
:: This prevents Firefox from asking if it can be the default.

call:inc func_msg ^
    "This script will stop Firefox from asking to be set as the default browser." ^
    "START" "Set Firefox to not ask to be default" ^
    "Firefox will be opened and automatically closed after 10 seconds. Please do not enter any inputs" ^
    "when the Firefox window opens. The script will continue after Firefox has been closed."

set "ff_userprefs=%OS_DRIVE%\Users\%current_user%\AppData\Roaming\Mozilla"
set "ff_userprefs=%ff_userprefs%\Firefox\Profiles\*.default-release\user.js"

start "firefox" /min "%OS_DRIVE%\Program Files\Mozilla Firefox\firefox.exe"
echo.
echo Waiting 10 seconds. . .
timeout 10 /nobreak >nul

set "ff_userprefs=%OS_DRIVE%\Users\%current_user%\AppData\Roaming\Mozilla"
set "ff_userprefs=%ff_userprefs%\Firefox\Profiles"

:: find the correct user profile (*.default-release) and append to path
pushd "%ff_userprefs%"
dir * /b | findstr /c:"default-release" > configure_temp.txt 
set /p ff_userprefs_profile= <configure_temp.txt
del configure_temp.txt
set "ff_userprefs_profile=!ff_userprefs_profile: =!"

set "ff_userprefs=%ff_userprefs%\%ff_userprefs_profile%\user.js"
popd

type nul > "%ff_userprefs%"
echo user_pref("browser.shell.checkDefaultBrowser", false); > %ff_userprefs%
taskkill /im firefox.exe >nul 2>&1
:: don't kill firefox forcefully otherwise it will complain on next open

call:inc func_log "DONE" "Set Firefox to not ask to be default done"

:Firefox_Skip

:: ===== MICROSOFT OFFICE =====================================================

call:inc func_progressbar_inc "Set Microsoft Word to Install Updates Only"

:: Check if MS Office is installed
call:inc func_check_if_exists ^
    "%OS_DRIVE%\Program Files\Microsoft Office\Office16\WINWORD.exe"
if not %errorlevel% == 0 (
    call:inc func_log "INFO" "Microsoft Word update policy skipped"
    goto MSWORD_Skip
)

:: Ask user to set Microsoft Office update policy and confirm
call:inc func_msg ^
    "This script will open Microsoft Word 2016. Please select Install updates only in the EULA menu." ^
    "START" "Set Microsoft Word to install updates only"

%HEADER%
echo You will be asked to enter the password for the current user below.
echo No feedback will be shown as you enter the password.
echo.
runas /noprofile /savecred /user:%current_user% "%OS_DRIVE%\Program Files\Microsoft Office\Office16\WINWORD.exe"

:Set_MSWORD_Update
%HEADER%
echo Please set Microsoft Word 2016 to install updates only.
echo.
set "result="
set /p "result=Type y and press enter once you have set the update policy: "
call:inc func_check_confirmation "!result!" ^
    Set_MSWORD_Update_done ^
    Set_MSWORD_Update
goto !confirm_result!

:Set_MSWORD_Update_done
call:inc func_log "DONE" "Set Microsoft Word to install updates only done"
:MSWORD_Skip

@REM call:inc func_msg ^
@REM     "This script will set Microsoft Word to install updates only." ^
@REM     "START" "Microsoft Office install updates only"

@REM reg add "HKLM\SOFTWARE\policies\microsoft\office\16.0\common\OfficeUpdate" ^
@REM     /v EnableAutomaticUpdates /t REG_DWORD /d 1 /f >nul
@REM reg add "HKLM\SOFTWARE\policies\microsoft\office\16.0\common\OfficeUpdate" ^
@REM     /v HideEnableDisableUpdates /t REG_DWORD /d 1 /f >nul
@REM call:inc func_log "DONE" "Microsoft Office install updates only done"

@REM %REG_ALWAYS_UPDATE%

:: ===== EDGE ================================================================= 

call:inc func_progressbar_inc "Disable First-Run Experience and Default Browser Prompt in Edge"

:: Hides the first-run experience and splash screen when Edge is launched for the first time
call:inc func_msg ^
    "This script will automatically disable the first-run experience and splash screen in Edge." ^
    "START" "Disable Edge first-run experience and splash screen and default browser prompt" ^
    "Note that this will only take effect after you log out of this user and log back in." ^
    "This script will also disable Edge from asking to be the default browser."

:: adds registry entry to disable the first run experience
reg add %user_hive%\SOFTWARE\Policies\Microsoft\Edge /v HideFirstRunExperience /t REG_DWORD /d 1 /f >nul

:: disables edge asking to be default
reg add %user_hive%\SOFTWARE\Policies\Microsoft\Edge /v DefaultBrowserSettingEnabled /t REG_DWORD /d 0 /f >nul

call:inc func_log "DONE" "Disable Edge first-run experience and splash screen and default browser prompt done"

%REG_ALWAYS_UPDATE%

:: ===== ONEDRIVE ============================================================= 

call:inc func_progressbar_inc "Disable OneDrive from Running on Startup"

call:inc func_msg ^
    "This script will disable OneDrive from running on startup." ^
    "START" "OneDrive disable run at startup"

reg delete %user_hive%\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v OneDrive /f >nul

call:inc func_log "DONE" "OneDrive disable run at startup done"

%REG_ALWAYS_UPDATE%

:: ===== WINDOWS SECURITY ===================================================== 

call:inc func_progressbar_inc "Dismiss Windows Security Warnings"

:Window_Security
call:inc func_msg ^
    "This script will open the Windows Security settings panel after you press any key." ^
    "START" "Windows Security dismiss concerns" ^
    "Please dismiss all concerns in the Windows Security settings panel."

start windowsdefender:

:Windows_Security_check
%HEADER%
echo Please confirm that you have dismissed all concerns in the Windows Security settings panel.
echo.
set "sec_answer="
set /p "sec_answer=Type y and press enter once you have dismissed all concerns: "
call:inc func_check_confirmation "!sec_answer!" ^
    Windows_Security_done ^
    Windows_Security_check
goto !confirm_result!

:Windows_Security_done
call:inc func_log "DONE" "Windows Security dismiss concerns done"

:: ===== SIGN-IN SETTINGS ===================================================== 

call:inc func_progressbar_inc "Disable Sign-In Info to Finish Device Setup After an Update"

call:inc func_msg ^
    "This script will disable the use of sign-in info to finish device setup after an update." ^
    "START" "Disable sign-in to finish setup after restart"

reg add %user_hive%\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v DisableAutomaticRestartSignOn /t REG_DWORD /d 1 /f >nul

call:inc func_log "DONE" "Disable sign-in to finish setup after restart done"

%REG_ALWAYS_UPDATE%

:: ===== DISABLE SEARCH BAR =================================================== 

call:inc func_progressbar_inc "Set Search Bar to be Hidden"

call:inc func_msg ^
    "This script will hide the search bar from appearing on the taskbar." ^
    "START" "Set search bar to be hidden"

:: Set the search bar to be hidden
reg add %user_hive%\SOFTWARE\Microsoft\Windows\CurrentVersion\Search /v SearchboxTaskbarMode /t REG_DWORD /d 0 /f >nul

call:inc func_log "DONE" "Set search bar to be hidden done"

%REG_ALWAYS_UPDATE%

:: ===== DISABLE CORTANA ====================================================== 

call:inc func_progressbar_inc "Set Cortana to be Hidden"

call:inc func_msg ^
    "This script will hide Cortana from appearing on the taskbar." ^
    "START" "Set Cortana to be hidden"

:: Set Cortana to be hidden
reg add %user_hive%\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v ShowCortanaButton /t REG_DWORD /d 0 /f >nul

call:inc func_log "DONE" "Set Cortana to be hidden done"

%REG_ALWAYS_UPDATE%

:: ===== SET TASKBAR SHORTCUTS ================================================ 

call:inc func_progressbar_inc "Set Taskbar Shortcuts"

call:inc func_msg ^
    "This script will set the taskbar shortcuts." ^
    "START" "Set taskbar shortcuts"

:: Remove all shortcuts on the taskbar except for the File Explorer shortcut by:
:: 1. Removing all non-File Explorer shortcuts in the shortcuts directory
:: 2. Creating a File Explorer shortcut in the shortcuts directory if it doesn't exist
:: 3. Initializing the binary magic number -- extracted from target environment registry
:: 4. Applying the binary data and other dword data to the registry entries
:: Note that changes will be applied when the desktop environment (explorer.exe) is restarted,
:: which will happen at the end of the script
for %%i in ("%OS_DRIVE%\Users\%current_user%\AppData\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*") do ( 
    if /i not "%%~nxi"=="File Explorer.lnk" del "%%i"
)

if not exist "%OS_DRIVE%\Users\%current_user%\AppData\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\File Explorer.lnk" (
    powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%OS_DRIVE%\Users\%current_user%\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\File Explorer.lnk');$s.TargetPath='%OS_DRIVE%\Windows\explorer.exe';$s.Save()"
)

         set "f_ex_sc=00a40100003a001f80c827341f105c1042aa032ee45287d668260001002600efbe12000000dfc37d6fa0b1d9015ef3d7bda0b1d901ecacfbbda0b1d901140056"
set "f_ex_sc=%f_ex_sc%00310000000000e856276c11005461736b42617200400009000400efbee856276ce856276c2e0000005c89000000000200000000000000000000000000000014"
set "f_ex_sc=%f_ex_sc%dced005400610073006b00420061007200000016001201320097010000874f0749200046494c4545587e312e4c4e4b00007c0009000400efbee856276ce85627"
set "f_ex_sc=%f_ex_sc%6c2e0000005e890000000002000000000000000000520000000000589c4400460069006c00650020004500780070006c006f007200650072002e006c006e006b"
set "f_ex_sc=%f_ex_sc%00000040007300680065006c006c00330032002e0064006c006c002c002d003200320030003600370000001c00120000002b00efbeecacfbbda0b1d9011c0042"
set "f_ex_sc=%f_ex_sc%0000001d00efbe02004d006900630072006f0073006f00660074002e00570069006e0064006f00770073002e004500780070006c006f0072006500720000001c"
set "f_ex_sc=%f_ex_sc%00260000001e00efbe0200530079007300740065006d00500069006e006e006500640000001c000000ff"

reg add %user_hive%\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband /v Favorites /t REG_BINARY /d %f_ex_sc% /f >nul

reg add %user_hive%\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband\AuxilliaryPins /v MailPin /t REG_DWORD /d 0 /f >nul

call:inc func_log "DONE" "Set taskbar shortcuts done"

%REG_ALWAYS_UPDATE%

:: ===== SET NOTIFICATION SETTINGS ============================================ 

call:inc func_progressbar_inc "Set Notification Settings"

call:inc func_msg ^
    "This script will disable app icon notifications and the display of the number of new notifications." ^
    "START" "Set notification settings"

:: Set notifications to not show app icons and not show number of new notifications

reg add %user_hive%\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings /v NOC_GLOBAL_SETTING_BADGE_ENABLED /t REG_DWORD /d 0 /f >nul

reg add %user_hive%\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings /v NOC_GLOBAL_SETTING_GLEAM_ENABLED /t REG_DWORD /d 0 /f >nul

call:inc func_log "DONE" "Set notification settings done"

%REG_ALWAYS_UPDATE%

:: ===== REGISTRY UPDATE AND END ==============================================

call:inc func_progressbar_inc "Update Local Group Policy, Registry, and Explorer Desktop Environment"

call:inc func_msg ^
    "The script will update the local group policies if not previously updated." ^
    "INFO" "Registry update and Explorer restart" ^
    "The script will also restart the Explorer desktop environment."

:: Update gp and registry if not done already
if "%registry_always_update%" == "n" ( powershell gpupdate )

:: Close the desktop environment
taskkill /im explorer.exe /f >nul
echo.
echo The desktop environment will restart in 3 seconds. . .
timeout /t 3 /nobreak >nul

:: Restart the desktop environment
:: The user needs to enter the user account password for runas to work --
:: there is no way around this
:: We run the start explorer again as the user (rather than the admin)
runas /noprofile /savecred /user:%current_user% explorer.exe

%HEADER%
echo If the desktop environment has not restarted, please open Task Manager using Ctrl+Shift+Esc,
echo press File, press "Run new task", type explorer.exe, and then press Enter.

call:inc func_log "DONE" "User_Setup_configure.bat"

call:inc func_end_script logoff 0
exit /b 0

:: ============================================================================
:: ===== COMMON FUNCTIONS =====================================================
:: ============================================================================

:: Calls external function
:inc
    pushd %~dp0
    call "%PROGRAM_LIB_PATH%\__common.bat" %*
    popd & exit /b %errorlevel%