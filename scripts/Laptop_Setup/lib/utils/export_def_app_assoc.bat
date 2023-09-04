@echo off
setlocal EnableDelayedExpansion
title %~nx0
cd /d "%~dp0"

echo The file will be put in the library directory.
echo.
set /p "name=What should the file be called?: "

pushd ..
set "libpath=%cd%"
popd

Dism /Online /Export-DefaultAppAssociations:"%libpath%\%name%.xml" >nul 

echo.
echo The file %libpath%\%name%.xml has been created.
pause
exit 0