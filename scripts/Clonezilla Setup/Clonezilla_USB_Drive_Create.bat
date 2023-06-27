:: Used to create a Clonezilla drive with clonezilla & image partition
:: This script needs the files:
::      /Clonezilla Bootable   - a directory containing the contents of Clonezilla
::      RemoveDrive.exe        - an executable that ejects the disk when given a volume letter argument
::
:: This script should be run on a Latitude 5320 with one internal disk

@echo off
cd %~dp0

set disk_num=1

:start


:: Confirm Disk Existence
cls
(
echo List Disk
echo Exit
) | diskpart > diskparttemplog.txt

find /c "Disk %disk_num%" diskparttemplog.txt >NUL
if %errorlevel%==1 goto end


:: Confirm Disk Selecion
echo:
echo:
findstr /c:"Disk" diskparttemplog.txt
echo:
echo:
echo Do you want to set up Disk %disk_num% for Clonezilla? (y/N) (default:n)
echo Please make sure Disk %disk_num% is NOT AN INTERNAL DISK. Disk %disk_num% will be PERMANENTLY WIPED.

set input=n
set /p input=
if /I not "%input%"=="y" (
    goto end
)

del diskparttemplog.txt


:: Use Diskpart
cls
echo Partitioning and formatting disk. . .
(
:: Remove Conflicting Drive Letters (just in case)
echo Select Volume D
echo Remove letter=D
echo Select Volume E
echo Remove letter=E

:: Select Clonezilla Drive and Clean
echo Select Disk %disk_num%
echo Clean
echo Convert gpt

:: Clonezilla Partition
echo Create Partition Primary Size=512
echo Format fs=FAT32 Quick label="Clonezilla"
echo Assign letter=D

::Images Partition
echo Create Partition Primary
echo Format fs=exFAT Quick label="Images"
echo Assign letter=E

echo Exit
) | diskpart >nul


:: Verify Clonezilla files exist
:verify_clonezilla
cls
if not exist "Clonezilla Bootable"\ (
    echo Error: "Clonezilla Bootable" folder does not exist
    echo Please copy over "Clonezilla Bootable" folder before continuing
    pause
    goto verify_clonezilla
)


:: Copy Clonezilla into Clonezilla partition
cls
echo Copying Clonezilla files into Clonezilla partition. . . 
xcopy /s /e /h /i /y "Clonezilla Bootable"\* D:\ >NUL


:: Eject Drive
cls
echo Ejecting Disk %disk_num%. . .
RemoveDrive.exe D: -L >NUL

set /a disk_num=disk_num+1
goto start


:: Finish
:end

del diskparttemplog.txt
cls

echo:
echo:
echo Clonezilla Drive creation complete! Exiting in 3 seconds
timeout /t 3 >NUL
exit
