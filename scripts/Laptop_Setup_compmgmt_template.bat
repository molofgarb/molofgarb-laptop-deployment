@echo off
cd %~dp0

:: Switch to case depending on prefix
:Start_compmgmt
goto case_compmgmt_%prefix%
if errorlevel 1 goto case_compmgmt_default
:: --------------------------
:case_compmgmt_XXX
net user staff1 /Active:No
net user staff2 /Active:Yes
net user staff3 /Active:No

net user admin1 /Active:No
net user admin2 /Active:Yes
net user admin3 /Active:No

for /f "skip=2" %%i IN (secrets.txt) DO if not defined line set "result=%%i" & goto XXX_staff_done

:XXX_staff_done
net user staff2 "%result%"

goto case_compmgmt_done
:: --------------------------
:: copy the section above for however many setup cases you have, with XXX being the prefix
:: --------------------------
:case_compmgmt_default
echo The prefix you've previously entered seems to be invalid.
echo If this is an error, contact the author of this script
echo You will be sent back to the computer name instruction to enter a valid prefix.
%pause_until_done%
exit /b 1
:: --------------------------
:case_compmgmt_done
%header%
echo Computer account management finished.
%pause_until_done%
exit /b 0