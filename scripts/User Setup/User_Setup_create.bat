:: Run this as an administrator to create a user. This should be run before User_Setup_configure.bat
:: If you have any questions or issues, please contact the author of this script.

@echo off
cd /d "%~dp0"

:: MACROS
set "header=cls & echo =============================================================================== & echo User Setup Script & echo =============================================================================== & echo."
set "pause_until_done=echo Press any key to continue. . . & pause > nul"
set "secrets=User_Setup_secrets.txt"

:: ===== CREATE USER ==========================================================

%header%
set /p "username=Please enter the username: "
echo.
set /p "fullname=Please enter the full name: "
cls

for /f "skip=0" %%i IN (%secrets%) DO if not defined line set "result=%%i" & goto User_password_done
:User_password_done

:: Create the user, allow them to change password, and make password never expire
net user %username% %result% /active:Yes /fullname:%fullname% /passwordchg:yes 
wmic useraccount where "name=%username%" set PasswordExpires=false


%header%
echo User "%username%" created for %fullname%.
%pause_until_done%