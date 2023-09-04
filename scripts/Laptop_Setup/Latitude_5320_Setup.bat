:: Used to set up Latitude 5320. Please clone using latest image before running this script.
:: If you have any questions or issues, please contact the author of this script.
:: NOTE: The default dimensions of a cmd.exe window is 120 width, 30 height

@echo off
setlocal EnableDelayedExpansion
color 0f
title %~nx0
cd /d "%~dp0"

:: All variables in all caps are GLOBAL
::
:: These variables need to be re-initialized in lib\__common.bat:func_check_admin
:: so that their value is preserved when the parent script is restarted as an
:: administrator  
::
:: The default values of these variables also need to be initialized in each
:: script in case they are run directly instead of through the main menu

:: Controls if func_msg should pause whenever a msg is displayed
set "NOPAUSE=disabled"

:: Controls if logs should also be written to the Desktop of the current user
set "LOCALLOG=disabled"

:: This allows sub-scripts to return to this script instead of closing
:: If this is not defined in a script, then it should stay undefined
:: This affects what happens when the script is "closed" when func_end_script
:: is called
set "MAINMENU=%~f0"

:: This is used to keep track of whether the Table of Contents for a particular
:: script has been shown to the user so that they aren't shown the table of
:: contents twice after restarting the script with administrator privileges
:: This variable should reset to n every time the user returns to the main menu
set "TOC=y"

set "script_prompt=Please enter the # of the script that you would like to use: "

:: Check if the scripts (dependencies) exist
set "device_name=Laptop"
set "script_path=Laptop_scripts"

if exist lib\__common.bat (set common=0) else (set common=1)
if exist %script_path%\Laptop_Setup_prep.bat (set prep=0) else (set prep=1)
if exist %script_path%\Laptop_Setup_update.bat (set update=0) else (set update=1)
if exist %script_path%\User_Setup_create.bat (set create=0) else (set create=1)
if exist %script_path%\User_Setup_configure.bat (set configure=0) else (set configure=1)
set /a "missing=%common%+%prep%+%update%+%create%+%configure%"

:: Let user know what scripts are missing if any
if %missing% == 0 (goto init)
echo WARNING: The following %missing% scripts are missing:
if %common% == 1 (echo -	__common.bat)
if %prep% == 1 (echo -	Laptop_Setup_prep.bat)
if %update% == 1 (echo -	Laptop_Setup_update.bat)
if %create% == 1 (echo -	User_Setup_create.bat)
if %configure% == 1 (echo -	User_Setup_configure.bat)
echo.
echo Please get the setup script files again.
echo The script will end now.
echo.
echo Press any key to close the script. . . & pause >nul

:: Main screen (main menu)
:init
call:header
call:script_list

:: Prompt for input
setlocal EnableDelayedExpansion
set /p "script=!script_prompt!"
endlocal & set "script=%script%"

call:case_%script%

set "script_prompt=Please enter the # of the script that you would like to use: "
if not %errorlevel% == 0 (
    set script_prompt="Please enter a valid script #: "
    goto init
)
goto init


:: NOTE: These calls never come back because each script should end in its own "exit 0"
:case_1
:case_Laptop_Setup_prep.bat
    call %script_path%\Laptop_Setup_prep.bat
    exit /b 0

:case_2
:case_Laptop_Setup_update.bat
    call %script_path%\Laptop_Setup_update.bat
    exit /b 0

:case_3
:case_User_Setup_create.bat
    call %script_path%\User_Setup_create.bat
    exit /b 0

:case_4
:case_User_Setup_configure.bat
    call %script_path%\User_Setup_configure.bat
    exit /b 0

:: Info menu
:case_a
:case_A
    call:header
    echo -  Laptop_Setup_prep is used after cloning a laptop to prepare the 
    echo    laptop name, user/admin accounts, BitLocker, etc.
    echo.
    echo -  Laptop_Setup_update is used to update the laptop by running
    echo    Windows update, Dell Command ^| Update, browser updaters, 
    echo    Zoom updater, etc.
    echo.
    echo -  User_Setup_create is used to create a new local user account 
    echo    and set the default password settings
    echo.
    echo -  User_Setup_configure is used on a local user account to configure 
    echo    the desktop environment to a standard setup
    echo.
    echo Press any key to return to the selection menu. . . & pause >nul
    exit /b 0


:case_s
:case_S
    echo.
    set /p "clear=Are you sure that you want to clear your logs directory? (y/n, default: n) "

    call:case_clear_logs_%clear%
    if not %errorlevel% == 0 ( exit /b 0 )

    :case_clear_logs_y
    :case_clear_logs_Y
        del /f /q %cd%\logs
        rmdir /q logs
        exit /b 0


:case_d
:case_D
    echo.
    set /p "clear=Are you sure that you want to clear your installers directory? (y/n, default: n) "

    call:case_clear_installers_%clear%
    if not %errorlevel% == 0 ( exit /b 0 )

    :case_clear_installers_y
    :case_clear_installers_Y
        del /f /q %cd%\installers
        rmdir /q installers
        exit /b 0


:case_f
:case_F
    setlocal EnableDelayedExpansion
    if "!LOCALLOG!" == "disabled" ( 
        set "LOCALLOG=enabled" 
    ) else ( 
        set "LOCALLOG=disabled" 
    )
    endlocal & set "LOCALLOG=%LOCALLOG%"
    exit /b 0


:case_g
:case_G
    setlocal EnableDelayedExpansion
    if "!NOPAUSE!" == "disabled" ( 
        set "NOPAUSE=enabled"
    ) else ( 
        set "NOPAUSE=disabled" 
    )
    endlocal & set "NOPAUSE=%NOPAUSE%"
    exit /b 0


:header
cls
echo ============================================================================== 
echo ============================================================================== 
echo ====                                                                      ==== 
echo ====                          %device_name%                          ==== 
echo ====                             Scripts Menu                             ==== 
echo ====                                                                      ==== 
echo ============================================================================== 
echo ============================================================================== 
echo.
exit /b 0


:script_list
setlocal EnableDelayedExpansion
echo Welcome to the %device_name% Scripts Menu^!
echo The available scripts are:
echo.
echo [96m(1)    Prepare Laptop		(Laptop_Setup_prep.bat)
echo [92m(2)    Update Laptop Programs	(Laptop_Setup_update.bat)
echo [36m(3)    Create New User		(User_Setup_create.bat)
echo [93m(4)    Configure User Setup	(User_Setup_configure.bat)
echo.
echo [97m(a)    Info about each script
echo (s)    Clear logs directory
echo (d)    Clear installers directory
echo (f)    Toggle local (on desktop) logs   (local log: !LOCALLOG!)
echo (g)    Toggle fast mode for script      (fast mode: !NOPAUSE!) 
echo.
endlocal
exit /b 0