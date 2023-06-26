@echo off
cd /d "%~dp0"

:: Creates PIN using our format
:Bitlocker_PIN_create
set "bitlocker_PIN=my_bitlocker_pin"


:: Activates BitLocker using the PIN that we made
:Bitlocker_start
cd C:\Windows\system32
%header%
manage-bde.exe -on C: -rp -tp %bitlocker_PIN%
%pause_until_done%


:: Saves the recovery password to the root directory of a volume in a text file that follows our format
:Bitlocker_save
%header%
(echo List Volume) | diskpart 
set volume_input=C
echo Which volume root should the BitLocker recovery password be saved to? Please enter a single capital letter. (default:C)
set /p volume_input=

%header%
manage-bde.exe -protectors -get C: -t recoverypassword > "%volume_input%:\BitLocker Recovery Key.txt"
echo BitLocker recovery password successfully saved to file: %volume_input%:\BitLocker Recovery Key
%pause_until_done%

cd /d "%~dp0"
exit /b 0