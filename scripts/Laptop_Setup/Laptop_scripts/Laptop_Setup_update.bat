:: Used to set up Latitude 5320. Please clone using latest image before running this script.
:: If you have any questions or issues, please contact the author of this script.

@echo off
setlocal EnableDelayedExpansion
color 0a

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

call:inc func_log_init "Latitude 5320 Update"
call:inc func_progressbar_init "%~f0"

:: Initial checks
:: Note: each check performs one progressbar increment
call:inc func_check_admin
call:inc func_check_internet
call:inc func_check_in_path "msiexec"
call:inc func_check_in_path "certutil"

:: Note that %ser_tag% is set by func_log_init
call:inc func_log "START" "%~0"
call:inc func_log "INFO" "The service tag is %ser_tag%"
call:inc func_log "INFO" "The shell user is %username%"
call:inc func_log "INFO" "The current logged in user is %current_user%"

:: ===== WINDOWS UPDATE START ==========================================

call:inc func_progressbar_inc "Begin Windows Update"

call:inc func_msg ^
    "The script will begin downloading an installing Windows updates." ^
    "START" "USOClient start" ^
    "A settings panel window will open and then be automatically closed after 10 seconds." ^
    "Please do not enter any inputs when the settings panel window opens."

%OS_DRIVE%\Windows\System32\control.exe /name Microsoft.WindowsUpdate

:: These two functions begin downloading and installing Windows updates in the background
:: Warning: this is a Microsoft internal use function -- it is very quiet
::          however it doesn't do anything evil so it should be fine to execute
call:inc func_log "INFO" "USOClient start interactive scan"
USOClient StartInteractiveScan

call:inc func_log "INFO" "USOClient silent Windows Update scan and download"
USOClient ScanInstallWait

call:inc func_log "INFO" "USOClient silent Windows Update installation"
USOClient StartInstall

timeout 10 /nobreak >nul
taskkill /im SystemSettings.exe /f

:: ===== DELL =================================================================

call:inc func_progressbar_inc "Dell Command Update"

call:inc func_check_if_exists ^
    "%OS_DRIVE%\Program Files\Dell\CommandUpdate\dcu-cli.exe"
if not %errorlevel% == 0 (
    call:inc func_log "INFO" "Dell Command Update skipped"
    goto Dell_Command_Update_Skip
)

call:inc func_msg ^
    "This script will open a Dell Command Update CLI process. It will install all updates." ^
    "START" "Dell Command Update CLI updates started" ^
    "The Dell Command Update logs will be stored in the logs directory."

:DCU
%HEADER%
echo This script will resume once all updates are complete. . .
call:inc func_log "INFO" "Calling dcu-cli.exe"
"%OS_DRIVE%\Program Files\Dell\CommandUpdate\dcu-cli.exe" ^
    /applyUpdates -reboot=disable -autoSuspendBitLocker=enable -forceupdate=enable ^
    -outputLog=%PROGRAM_LOG_PATH%\%ser_tag%_DCU.log

call:inc func_check_msi_install "%PROGRAM_LOG_PATH%\%ser_tag%_DCU.log"
if %errorlevel% == 0 ( goto DCU_successful )

call:inc func_msg ^
    "The script will retry Dell Command Update." ^
    "INFO" "Retrying Dell Command Update"
goto DCU


:DCU_successful
call:inc func_msg ^
    "The Dell Command Update process has finished installing updates." ^
    "INFO" "Dell Command Update CLI finished"

call:inc func_log "INFO" "The Dell Command Update log can be found in logs\%ser_tag%_DCU.log"
call:inc func_log "DONE" "Dell Command Update CLI updates completed"

:Dell_Command_Update_Skip

:: ===== FIREFOX ============================================================== 

call:inc func_progressbar_inc "Firefox Update"

call:inc func_msg ^
    "This script will automatically update Firefox." ^
    "START" "Firefox update"

:: Download newest Firefox installer
call:inc func_download_from_URL ^
    "https://download.mozilla.org/?product=firefox-msi-latest-ssl&os=win64&lang=en-US" ^
    Firefox msi

:: Run the Firefox installer and have it generate a log
:: Note: for some reason, the Firefox .msi doesn't support some standard .msi args
:Firefox_Install
%HEADER%
echo Installing latest Firefox update from Firefox_%FORMATTED_DATE%.msi. . .
msiexec /i "%PROGRAM_INSTALLER_PATH%\Firefox_%FORMATTED_DATE%.msi" /q ^
    /L "%PROGRAM_LOG_PATH%\%ser_tag%_Firefox.log"

call:inc func_check_msi_install "%PROGRAM_LOG_PATH%\%ser_tag%_Firefox.log"
if %errorlevel% == 0 ( goto Firefox_Install_successful )

call:inc func_msg ^
    "The script will retry the installation of Firefox_%FORMATTED_DATE%.msi." ^
    "INFO" "Retrying install of Firefox_%FORMATTED_DATE%.msi"
goto Firefox_Install


:Firefox_Install_successful
call:inc func_msg ^
    "The Firefox update was successful." ^
    "INFO" "Firefox .msi update complete"

call:inc func_log "INFO" "The Firefox log can be found in logs\%ser_tag%_Firefox.log"
call:inc func_log "DONE" "Firefox update done"

:: ===== CHROME ============================================================= 

call:inc func_progressbar_inc "Chrome Update"

call:inc func_msg ^
    "This script will automatically update Chrome." ^
    "START" "Chrome update"

:: Download newest Firefox installer
call:inc func_download_from_URL ^
    "https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi" ^
    Chrome msi

:: Run the Firefox installer and have it generate a log
:Chrome_Install
%HEADER%
echo Installing latest Chrome update from Chrome_%FORMATTED_DATE%.msi. . .
msiexec /i "%PROGRAM_INSTALLER_PATH%\Chrome_%FORMATTED_DATE%.msi" /qn ^
    /l* "%PROGRAM_LOG_PATH%\%ser_tag%_Chrome.log"

call:inc func_check_msi_install "%PROGRAM_LOG_PATH%\%ser_tag%_Chrome.log"
if %errorlevel% == 0 ( goto Chrome_Install_successful )

call:inc func_msg ^
    "The script will retry the installation of Chrome_%FORMATTED_DATE%.msi." ^
    "INFO" "Retrying install of Chrome_%FORMATTED_DATE%.msi"
goto Chrome_Install


:Chrome_Install_successful
call:inc func_msg ^
    "The Chrome update was successful." ^
    "INFO" "Chrome .msi update complete"

call:inc func_log "INFO" "The Chrome log can be found in logs\%ser_tag%_Chrome.log"
call:inc func_log "DONE" "Chrome update done"

:: ===== ZOOM ================================================================= 

call:inc func_progressbar_inc "Zoom Update"

call:inc func_msg ^
    "This script will automatically update Zoom." ^
    "START" "Zoom update"

:: Download newest Zoom installer
call:inc func_download_from_URL ^
    "https://zoom.us/client/latest/ZoomInstallerFull.msi?archType=x64" ^
    Zoom msi

:: Run the Zoom installer (and enable auto updates) and have it generate a log
:Zoom_Install
%HEADER%
echo Installing latest Zoom update from Zoom_%FORMATTED_DATE%.msi. . .
msiexec /i "%PROGRAM_INSTALLER_PATH%\Zoom_%FORMATTED_DATE%.msi" /qn ^
    /l* "%PROGRAM_LOG_PATH%\%ser_tag%_Zoom.log"

call:inc func_check_msi_install "%PROGRAM_LOG_PATH%\%ser_tag%_Zoom.log"
if %errorlevel% == 0 ( goto Zoom_Install_successul )

call:inc func_msg ^
    "The script will retry the installation of Zoom_%FORMATTED_DATE%.msi." ^
    "INFO" "Retrying install of Zoom_%FORMATTED_DATE%.msi"
goto Zoom_Install


:Zoom_Install_successul
call:inc func_msg ^
    "The Zoom update was successful." ^
    "INFO" "Zoom .msi update complete"

call:inc func_log "INFO" "The Zoom log can be found in logs\%ser_tag%_Zoom.log"
call:inc func_log "DONE" "Zoom update done"

:: ===== WINDOWS UPDATE ACTIVE CHECK ==========================================

call:inc func_progressbar_inc "Windows Update Check"

:Start_Windows_Update
call:inc func_msg ^
    "This script will open the Windows Update panel to start a Windows Update check." ^
    "START" "Windows Update check" ^
    "Instructions for Windows Update will be given once the panel is open."

%OS_DRIVE%\Windows\System32\control.exe /name Microsoft.WindowsUpdate

:Check_Windows_Update
call:inc func_log "INFO" "Prompting user to check that all Windows Updates have been completed"
%HEADER%
echo Please check, download, and install all Windows updates, including the optional updates.
echo An update has finished installing when the status of that update is "Pending restart".
echo Once all updates have finished installing, please confirm in the prompt below.
echo.

set "result="
set /p "result=Type y and press enter once all updates have finished installation: "
call:inc func_check_confirmation "!result!" ^
    Check_Windows_Update_done ^
    Check_Windows_Update
goto !confirm_result!

taskkill /im SystemSettings.exe /f

:Check_Windows_Update_done
call:inc func_log "DONE" "Laptop_Setup_update.bat"

echo.
echo It is recommended that you run User_Setup_create.bat if you need to create a user on the laptop.
echo.

call:inc func_end_script ask_restart 0
exit /b 0


:: ============================================================================
:: ===== COMMON FUNCTIONS =====================================================
:: ============================================================================

:: Calls external function
:inc
    pushd %~dp0
    call "%PROGRAM_LIB_PATH%\__common.bat" %*
    popd & exit /b %errorlevel%
