:: Used to change the FQDN of a computer according to the format: <prefix>-<ServiceTag>

@echo off
cd %~dp0

:: Get Service Tag
wmic bios get serialnumber | findstr /v "SerialNumber" > temp.txt

set /p ser_tag= <temp.txt
set ser_tag=%ser_tag: =%

del temp.txt


:: Get Prefix (from user)
set prefix=XXX
echo The prefix (e.g. REG) is: 
set /p prefix=
echo:


:: Set New Name
set new_name=%prefix%-%ser_tag%

echo The new computer name will be: %new_name%
echo:
cmd /c "wmic computersystem where name='%computername%' call rename name='%new_name%'"
echo:

echo If "ReturnValue = 0", then the name change was successful.
echo:
pause