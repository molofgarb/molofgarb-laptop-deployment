:: Run this as an user to configure parts of the environment. This should be run after User_Setup_create.bat
:: If you have any questions or issues, please contact the author of this script.

@echo off
cd /d "%~dp0"

:: MACROS
set "header=cls & echo =============================================================================== & echo User Setup Script & echo =============================================================================== & echo."
set "pause_until_done=echo Press any key to continue. . . & pause > nul"
set "defaults=User_Setup_defaultappassoc.xml"

:: ===== CONFIGURE USER ==========================================================

%header%
%pause_until_done%