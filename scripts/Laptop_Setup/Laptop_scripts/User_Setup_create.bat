:: Run this as an administrator to create a user. This should be run before User_Setup_configure.bat
:: If you have any questions or issues, please contact the author of this script.
@REM for /f "skip=0" %%i IN (%secrets%) DO if not defined line set "result=%%i" & goto User_password_done

@echo off
setlocal EnableDelayedExpansion
color 03

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

call:inc func_log_init "Latitude 5320 User Creation"
call:inc func_progressbar_init "%~f0"

:: Initial checks
:: Note: each check performs one progressbar increment
call:inc func_check_admin

:: Note that %ser_tag% is set by func_log_init
call:inc func_log "START" "%~0"
call:inc func_log "INFO" "The service tag is %ser_tag%"
call:inc func_log "INFO" "The shell user is %username%"
call:inc func_log "INFO" "The current logged in user is %current_user%"

:: ===== CREATE USER ==========================================================

:User_Creation_Inputs
call:inc func_log "START" "User creation begin"

call:inc func_progressbar_inc "Input: Username"

:: Prompt for username
:Get_Username
%HEADER%
set /p "setup_username=Please enter the username: "
echo.

:: Check to see if username is already in use
net user | findstr /c:"%setup_username%"
if not %errorlevel% == 0 ( goto Get_Username_done )

:: Username is already in use and new username must be specified
call:inc func_msg ^
    "The username %setup_username% is invalid or already in use by a local user." ^
    "ERROR" "Username %setup_username% is invalid or already in use" ^
    "Please choose another username."
goto Get_Username


:Get_Username_done
call:inc func_log "INFO" "The username is %setup_username%"

:: ------------------------------------

call:inc func_progressbar_inc "Input: Fullname"

:: Prompt for fullname
%HEADER%
set /p "setup_fullname=Please enter the full name: "
echo.
call:inc func_log "INFO" "The full name is %setup_fullname%"

:: ------------------------------------

call:inc func_progressbar_inc "User Creation Confirmation"

call:inc func_log "INFO" "User info confirmation: %setup_username%, %setup_fullname%" 

:User_Creation_Confirm
%HEADER%
echo The user account will be created for:
echo     Username: %setup_username%
echo     Fullname: %setup_fullname%
echo.
echo Please enter y to create the user.
echo Please enter n to return to the username input prompt.
echo.
set "result="
set /p "result=Confirm?: "
call:inc func_log "INFO" "User creation confirm answer: %result%"

if "%result%" == "y" ( goto User_Creation )
if "%result%" == "n" ( set "PROGRESSBAR_SKIP=-3" & goto User_Creation_Inputs )
goto User_Creation_Confirm

:: ------------------------------------

:User_Creation
call:inc func_progressbar_inc "User Creation"

call:inc func_check_password "_user" "user"

:: Create the user, allow them to change password, and make password never expire
setlocal DisableDelayedExpansion
net user "%setup_username%" "%password:~0,-1%" /add /active:Yes /fullname:"%setup_fullname%" /passwordchg:yes >nul & endlocal
wmic useraccount where name="%setup_username%" set PasswordExpires=false >nul

call:inc func_msg ^
    "User "%setup_username%" created for %setup_fullname%." ^
    "DONE" "User creation complete: username is %setup_username%, fullname is %setup_fullname%"

call:inc func_log "DONE" "User_Setup_create.bat"

%HEADER%
echo It is recommended that you run User_Setup_configure.bat when logged in as the user to configure the Windows environment.
echo.

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