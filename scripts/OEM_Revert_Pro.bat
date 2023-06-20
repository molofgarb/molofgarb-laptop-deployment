:: Used to restore Dell laptops to Windows 10 Pro
@echo off

wmic path softwarelicensingservice get OA3xOriginalProductKey | findstr /v OA3xOriginalProductKey > %temp%\temp.txt
set /p key=< %temp%\temp.txt
del %temp%\temp.txt

echo Windows 10 Pro Product Key: %key%

slmgr.vbs /ipk %key%

echo:
echo Windows 10 Pro activated!
echo Press any key to close. . . 
pause > nul
