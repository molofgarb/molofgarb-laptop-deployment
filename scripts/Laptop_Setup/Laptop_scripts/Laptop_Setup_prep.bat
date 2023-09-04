:: Used to set up Latitude 5320. Please clone using latest image before running this script.
:: If you have any questions or issues, please contact the author of this script.

@echo off
setlocal EnableDelayedExpansion
color 0b

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

call:inc func_log_init "Latitude 5320 Prep"
call:inc func_progressbar_init "%~f0"

:: Initial checks
:: Note: each check performs one progressbar increment
call:inc func_check_admin
call:inc func_check_internet
call:inc func_check_in_path "msiexec"

:: Note that %ser_tag% is set by func_log_init
call:inc func_log "START" "%~0"
call:inc func_log "INFO" "The service tag is %ser_tag%"
call:inc func_log "INFO" "The shell user is %username%"
call:inc func_log "INFO" "The current logged in user is %current_user%"

:: ===== SYNCHRONIZE DATE AND TIME ============================================

call:inc func_progressbar_inc "Check Date and Time"

:: Updates date and time
:Synchronize_Time
%HEADER%
echo Synchronizing time and date. . .
echo.
net start w32time >nul
w32tm /resync >nul

call:inc func_msg ^
    "Time synchronization complete. The date is [%date%] and the time is [%time%]." ^
    "INFO" "Time has been synchronized. The date and time is %date% %time%"

:: ===== ASK FOR DEPARTMENT ===================================================

call:inc func_progressbar_inc "Input: Department"

:: Get Department
:Department_Get
%HEADER%
echo Please type the number of the department that you would like to prep this laptop for.
echo For example, type 1 and press Enter if you want to prep this laptop for AAA.
echo (1)    AAA    - Department 1
echo (2)    BBB    - Department 2
echo (3)    CCC    - Department 3
echo.
set /p "dept=Please enter the department number: "
call:inc func_log "INFO" "The department # entry is %dept%"

:: validate input 
call:dept_switch_%dept% 2>nul
if not %errorlevel% == 0 (
    call:inc func_msg ^
        "Please enter a valid department." ^
        "ERROR" "Invalid department entered: %dept%"
    goto Department_Get
)

goto Department_done

:dept_switch_1
:dept_switch_AAA
    set "prefix=AAA"
    exit /b 0
:dept_switch_2
:dept_switch_BBB
    set "prefix=BBB"
    exit /b 0
:dept_switch_3
:dept_switch_CCC
    set "prefix=CCC"
    exit /b 0

:Department_done

call:inc func_log "INFO" "The prefix is %prefix%"

:: ===== MICROSOFT OFFICE START ===============================================

call:inc func_progressbar_inc "Start KMS"

:: Skip KMS installation if MS Office already licensed
pushd "%OS_DRIVE%\Program Files\Microsoft Office\Office16"
cscript ospp.vbs /dstatus | findstr /c:"---LICENSED---" >nul

if %errorlevel% == 0 (
    set "MS_OFFICE_SKIP=y"
    call:inc func_msg ^
        "KMS installation will be skipped because Microsoft Office is licensed on this computer." ^
        "INFO" "Start KMS skipped"
    popd
    goto KMS_Done
)

:: Starts KMS service to activate Microsoft Office License
:KMS_Start
call:inc func_check_if_exists "%KMS_MSI%"

:KMS_Install
%HEADER%
echo Installing %KMS_MSI%. . .
msiexec /i "%KMS_MSI%" /qn /l* "%PROGRAM_LOG_PATH%\%ser_tag%_KMS.log"

call:inc func_check_msi_install "%PROGRAM_LOG_PATH%\%ser_tag%_KMS.log"
if %errorlevel% == 0 ( goto KMS_Install_successful )

call:inc func_msg ^
    "The script will retry the installation of %KMS_MSI%." ^
    "INFO" "Retrying install of %KMS_MSI%"
goto KMS_Install


:KMS_Install_successful
call:inc func_msg ^
    "%KMS_MSI% has been installed." ^
    "INFO" "%KMS_MSI% installed"

call:inc func_log "START" "%KMS_MSI%"

call:inc func_check_VPN

:KMS_Done

:: ===== COMPUTER NAME ========================================================

call:inc func_progressbar_inc "Set Computer Name"

call:inc func_msg ^
    "The script will now set the computer name of the computer." ^
    "START" "Computer name set start"

:: Set new name for computer
set new_name=newname
call:inc func_log "INFO" "The old computer name is %computername%"
call:inc func_log "INFO" "The new computer name is %new_name%"

cmd /c "wmic computersystem where name='%computername%' call rename name='%new_name%'" >nul

call:inc func_msg ^
    "The computer name has been set to: %new_name%" ^
    "DONE" "Computer name set complete"

:: ===== DISABLE WIN11 UPGRADE ================================================

call:inc func_progressbar_inc "Disable Windows 11 Upgrade"

call:inc func_msg ^
    "The script will disable the Windows 11 upgrade." ^
    "START" "Disable Win11 upgrade"

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" ^
    /v ProductVersion           /t REG_SZ /d "Windows 10"   /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" ^
    /v TargetReleaseVersionInfo /t REG_SZ /d "22H2"         /f >nul

:: Local group policy update will occur later in BitLocker section
:: There is no need to waste time on it here

call:inc func_msg ^
    "The Windows 11 upgrade has been disabled." ^
    "DONE" "Disable Win11 upgrade complete"

:: ===== ACCOUNT MANAGEMENT ===================================================

call:inc func_progressbar_inc "Set Local Accounts by Department"

:: required variables are: header, pause_until_done, prefix
call:inc func_msg ^
    "The script will now set the local accounts on the computer according to the department: %prefix%" ^
    "START" "Computer account management start"

call:inc func_log "START" "func_compmgmt, switching to case %prefix%"

:: DANGER!! DANGER!! disabling ALL accounts on computer!! DANGER!!
:: If Windows BSODs or logs you out right after this command, then installation is bricked
:: I hope you have an image ready
wmic useraccount where localaccount=true set disabled=true >nul

:: Safety precaution in case one of the next statements fail
net user Administrator /Active:Yes >nul

call:inc func_log "INFO" "Disabled all accounts, enabled Administrator for safety"

:: Check if these accounts exist and prompt user to create them if not
call:func_compmgmt_check_acct user1
call:func_compmgmt_check_acct user2
call:func_compmgmt_check_acct user3
call:func_compmgmt_check_acct admin1
call:func_compmgmt_check_acct admin2
call:func_compmgmt_check_acct admin3

:: Make sure that admin accounts have admin privileges
call:inc func_log "INFO" "Setting admin accounts"
net localgroup administrators admin1    /add >nul 2>&1
net localgroup administrators admin2  /add >nul 2>&1
net localgroup administrators admin3 /add >nul 2>&1

%HEADER%
call:case_compmgmt_%prefix% 2>nul

if not %errorlevel% == 0 ( goto case_compmgmt_default )
goto case_compmgmt_done

:: Big switch case incoming
:: --------------------------
:case_compmgmt_AAA
    net user user1  /Active:Yes >nul 
    net user user2      /Active:No >nul 
    net user user3    /Active:No >nul 

    net user admin1      /Active:Yes >nul 
    net user admin2    /Active:No >nul 
    net user admin3   /Active:No >nul 

    :: -- Ask to Set admin password --
    %HEADER%
    echo If the laptop is newly imaged, you MUST set the admin password.
    echo.
    set "DEP_admin_password="
    set /p "DEP_admin_password=Do you want to set the admin password? (y/n, default: n): "
    call:inc func_log "INFO" "Admin password set: %result%"

    call:inc func_check_confirmation "%DEP_admin_password%" ^
        func_compmgmt_DEP_admin ^
        func_compmgmt_DEP_admin_done
    goto %confirm_result%

    :: Set admin password
    :func_compmgmt_DEP_admin
    call:inc func_check_password "admin_AAA" "DEP admin"

    setlocal DisableDelayedExpansion
    net user "admin1" "%password:~0,-1%" /passwordchg:yes & endlocal

    :func_compmgmt_DEP_admin_done

    :: -- Ask to Set staff password --
    %HEADER%
    echo If the laptop is newly imaged, you MUST set the staff password.
    echo.
    set "DEP_staff_password="
    set /p "DEP_staff_password=Do you want to set the staff password? (y/n, default: n): "
    call:inc func_log "INFO" "Staff password set: %result%"

    call:inc func_check_confirmation "%DEP_staff_password%" ^
        func_compmgmt_DEP_staff ^
        func_compmgmt_DEP_staff_done
    goto %confirm_result%

    :: Set staff password
    :func_compmgmt_DEP_staff
    call:inc func_check_password "staff_AAA" "DEP staff"

    setlocal DisableDelayedExpansion
    net user "user1" "%password:~0,-1%" /passwordchg:yes & endlocal

    :func_compmgmt_DEP_staff_done

    call:inc func_log "INFO" "DEP accounts set up"

    exit /b 0
:: --------------------------
:case_compmgmt_BBB
:: please see case_compmgmt_AAA, but activate users for BBB, check password with
:: BBB hashes, set password for BBB users

:: --------------------------
:case_compmgmt_CCC
:: please see case_compmgmt_AAA, but activate users for CCC, check password with
:: CCC hashes, set password for CCC users

:: --------------------------
:case_compmgmt_default
    echo The prefix you've previously entered seems to be invalid. If this 
    echo is an error, please contact the author of this script. 
    echo.
    echo As an emergency measure, the Administrator account is left active so that
    echo the Windows installation is still usable in case the device turns off.
    echo PLEASE GO TO COMPUTER MANAGEMENT, ENABLE THE APPROPRIATE ADMIN ACCOUNTS,
    echo AND THEN DISABLE THE ADMINISTRATOR ACCOUNT.

    call:inc func_log "ERROR" "Computer account management, invalid prefix"
    %PAUSE_UNTIL_DONE%
    exit /b 1
:: --------------------------
:case_compmgmt_done
    :: Remove safety precaution 
    net user Administrator /Active:No >nul

    call:inc func_log "DONE" "func_compmgmt, complete"
    

call:inc func_msg ^
    "Computer account management complete." ^
    "START" "Computer account management complete"

:: ===== MICROSOFT OFFICE CHECK ===============================================

call:inc func_progressbar_inc "Check Microsoft Office Licensing"

:: If previously asked to skip Microsoft Office licensing and KMS install,
:: then skip this part as well
if defined MS_OFFICE_SKIP (
    call:inc func_log "INFO" "Microsoft Office check skipped"
    goto Office_Skip
)

call:inc func_msg ^
    "The script will now check if Microsoft Office has been licensed on this computer." ^
    "START" "Microsoft Office check"

:Office_Check_License

:: Check if Microsoft Office had been installed
call:inc func_check_if_exists "%OS_DRIVE%\Program Files\Microsoft Office\Office16\WINWORD.EXE"
if not %errorlevel% == 0 (
    call:inc func_log "INFO" "Microsoft Office skipped"
    goto Office_Skip
)

:: Check license status
pushd "%OS_DRIVE%\Program Files\Microsoft Office\Office16"
cscript ospp.vbs /dstatus | findstr /c:"---LICENSED---" >nul

:: If Office has not yet been licensed
if not %errorlevel% == 0 (
    call:inc func_log "ERROR" "func_msoffice_check, Microsoft Office license activation pending"
    echo Microsoft Office has not yet been licensed as of %time%.
    echo License will be checked again in 5 seconds. . .
    
    timeout /t 5 /nobreak >nul
    goto Office_Check_License
)

popd

call:inc func_msg ^
    "Microsoft Office has been licensed by the KMS." ^
    "DONE" "func_msoffice_check, Microsoft Office license activation check complete"

:Office_Skip

:: --------------------------

:: Revert to OEM Windows 10 Pro license
call:inc func_progressbar_inc "Revert to OEM Windows License"

call:inc func_msg ^
    "The script will revert the Windows 10 license to Windows 10 Pro." ^
    "START" "func_msoffice_check, Revert to Windows 10 Pro OEM Key"

:: Get OEM key
%HEADER%
wmic path softwarelicensingservice get OA3xOriginalProductKey ^
    | findstr /v OA3xOriginalProductKey > %temp%\temp.txt
set /p key=< %temp%\temp.txt
del %temp%\temp.txt

echo Windows 10 Pro Product Key: %key%
call:inc func_log "INFO" "func_msoffice_check, The Windows 10 Pro product key is %key%"

:: Revert to OEM key
call:inc func_log "START" "func_msoffice_check, reverting to Pro using key"
slmgr.vbs /ipk %key%
call:inc func_log "DONE" "func_msoffice_check, reverting to Pro using key complete"

call:inc func_msg ^
    "Microsoft Office has been activated. Windows 10 Pro has been activated." ^
    "DONE" "Microsoft Office check complete"

:: ===== BITLOCKER ============================================================

call:inc func_progressbar_inc "BitLocker PIN Generation"

:: Check BitLocker -- if already on, then skip the BitLocker sections
manage-bde.exe -status %OS_DRIVE% | findstr /c:"Protection On" >nul 2>&1
if %errorlevel% == 0 (
    set "PROGRESSBAR_SKIP=3"
    call:inc func_msg ^
        "BitLocker will be skipped because BitLocker is enabled for this computer." ^
        "INFO" "BitLocker skipped"
    goto BitLocker_done
)

:: required variables are: header, pause_until_done, ser_tag
call:inc func_msg ^
    "The script will now configure BitLocker on this computer." ^
    "START" "BitLocker activation"


call:inc func_log "START" "func_bitlocker, BitLocker PIN generation start"

:: PIN generation
call:inc func_check_password "_bitlocker" "BitLocker"

call:inc func_log "DONE" "func_bitlocker, BitLocker PIN generation complete"

call:inc func_progressbar_inc "Turn On BitLocker"

:: Activates BitLocker using the PIN that we made
call:inc func_msg ^
    "The script will now enable BitLocker." ^
    "START" "func_bitlocker, BitLocker enable"

call:inc func_progressbar_inc "BitLocker Local Group Policies"

:: Set BitLocker local group policies
reg add "HKLM\Software\Policies\Microsoft\FVE" /v EnableBDEWithNoTPM /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Software\Policies\Microsoft\FVE" /v UseAdvancedStartup /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Software\Policies\Microsoft\FVE" /v UseEnhancedPin     /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Software\Policies\Microsoft\FVE" /v UseTPM             /t REG_DWORD /d 2 /f >nul
reg add "HKLM\Software\Policies\Microsoft\FVE" /v UseTPMKey          /t REG_DWORD /d 2 /f >nul
reg add "HKLM\Software\Policies\Microsoft\FVE" /v UseTPMKeyPIN       /t REG_DWORD /d 2 /f >nul
reg add "HKLM\Software\Policies\Microsoft\FVE" /v UseTPMPIN          /t REG_DWORD /d 2 /f >nul
echo.
echo BitLocker local group policies have been set.
echo.
echo Updating local group policy. . .

powershell gpupdate >nul
echo Local group policies have been updated.

:: BitLocker is either awaiting protectors, off with no protectors, off with protectors,
manage-bde.exe -status %OS_DRIVE% | findstr /c:"None Found" >nul

:: remove existing protectors -- this also disables bitlocker and partially decrypts
if not %errorlevel% == 0 (
    manage-bde.exe -protectors %OS_DRIVE% -delete >nul
)

:: create two protectors for OS drive: a recovery password protector and a TPMAndPIN protector
:: The setlocal stuff is needed for special chars in bitlocker password to be recognized
setlocal DisableDelayedExpansion
manage-bde.exe -protectors -add %OS_DRIVE% -rp -tp "%password:~0,-1%" >nul & endlocal
manage-bde.exe -protectors -enable %OS_DRIVE% >nul

:: turn BitLocker on if it doesn't turn on by itself (if it was off)
manage-bde.exe -on %OS_DRIVE% >nul

call:inc func_msg ^
    "BitLocker has been enabled." ^
    "DONE" "func_bitlocker, BitLocker enable done"

call:inc func_progressbar_inc "BitLocker Recovery Password File Generation"

:: Saves the recovery password to the root directory of a volume in a 
:: text file that follows our format
call:inc func_msg ^
    "The script will generate a file with the BitLocker recovery password." ^
    "START" "func_bitlocker, BitLocker recovery password file generation"

cd /d "%~dp0"
set "drive=%cd:~0,2%"
call:inc func_log "INFO" "The script is on drive %drive%"

:BitLocker_drive_check
:: If system drive, fail
if "!drive!" == "%OS_DRIVE%" ( goto BitLocker_drive_check_fail )

:: If not a valid drive, fail
cd %drive% >nul 2>&1
if not %errorlevel% == 0 ( goto BitLocker_drive_check_fail )

:: Otherwise it is a valid drive for recovery password file
goto BitLocker_drive_check_success

:: If the drive to save the recovery key is invalid or the same as the system drive
:BitLocker_drive_check_fail
%HEADER%
(echo List Volume) | diskpart | findstr /c:"Volume" /c:"---"
echo.
echo BitLocker Recovery Password cannot be saved to the volume: %drive%
echo Which volume root should the BitLocker recovery password be saved to? 
echo Please enter a single capital letter.
echo.
set /p "drive=Volume: "
call:inc func_log "INFO" "Recovery Password drive set to: !drive!"

set "drive=!drive!:"
goto Bitlocker_drive_check

:: Once it is verified that drive is a mounted external drive
:BitLocker_drive_check_success
set "rp_path=%drive%\"
call:inc func_log "INFO" "func_bitlocker, The BitLocker recovery password path is %rp_path%"

set "rp_file=%rp_path%%ser_tag% - %FORMATTED_DATE%_%FORMATTED_TIME% - BitLocker Recovery Key.txt"
call:inc func_log "INFO" "func_bitlocker, The BitLocker recovery password file is %rp_file%"

:: If, for some reason, there is already BitLocker for the same laptop for the same day
if exist "%rp_file%" (
    echo. >> "%rp_file%"
    echo ---------------------------------------------------------------------- >> "%rp_file%"
    echo. >> "%rp_file%"
) else (
    type nul > "%rp_file%"
)
call:func_bitlocker_rp_info "%rp_file%"

manage-bde.exe -protectors -get %OS_DRIVE% -t recoverypassword >> "%rp_file%"
attrib +r "%rp_file%"

:: Make PIN use a requirement
reg add "HKLM\Software\Policies\Microsoft\FVE" /v UseTPMPIN /t REG_DWORD /d 1 /f >nul
%HEADER%
echo BitLocker local group policies have been set to require PIN at boot.
echo.
echo Updating local group policy. . .

powershell gpupdate >nul
echo Local group policies have been updated.

call:inc func_msg ^
    "BitLocker recovery password successfully saved to file: %rp_file%" ^
    "DONE" "func_bitlocker, BitLocker recovery password file generation complete"


call:inc func_msg ^
    "BitLocker has been activated." ^
    "DONE" "BitLocker activation complete"

:BitLocker_done

:: ===== SET DEFAULT PROGRAMS ==================================================

call:inc func_progressbar_inc "Set Default User Programs Globally"

call:inc func_msg ^
    "The script will set the default user programs globally." ^
    "START" "Set Default User's Programs"

dism /Online /Import-DefaultAppAssociations:"%DEFAULTS%" >nul 

call:inc func_msg ^
    "The default user programs have been globally set." ^
    "START" "Set Default User's Programs done"

:: ===== BIOS PASSWORD AND MAC ================================================

call:inc func_progressbar_inc "BIOS Instructions"

call:inc func_log "INFO" "BIOS task prompting"
call:inc func_log "DONE" "Laptop_Setup_prep.bat"

%HEADER%
echo Please set up BIOS settings according to the setup document. 
echo It is recommended that you run Laptop_Setup_update.bat to update the programs on the laptop.
echo.

call:inc func_end_script close 0
exit /b 0


:: ============================================================================
:: ===== FUNCTIONS ============================================================
:: ============================================================================

:: Sub-function to check if a user exists and prompt creation if not
:: Don't run directly
:func_compmgmt_check_acct 

    call:inc func_log "INFO" "Checking if local account %~1 exists"
    
    net user "%~1" >nul 2>&1
    if %errorlevel% == 0 ( exit /b 0 )

    :: If the local account does not exist
    call:inc func_msg ^
        "WARNING: The local account %~1 does not exist." ^
        "ERROR" "Local account %~1 does not exist" ^
        "The script will create the %~1 account."

    :: The section below asks the user if they would like to create the missing account
    :: The user should always create the missing account so the section below has been commented out
    @REM %HEADER%
    @REM set "func_compmgmt_ucq="
    @REM set /p "func_compmgmt_ucq=Do you want to create %~1? (y/n, default: n): "

    @REM call:inc func_check_confirmation "%func_compmgmt_ucq%" ^
    @REM     func_compmgmt_check_acct_create ^
    @REM     func_compmgmt_check_acct_done
    @REM goto !confirm_result!

    @REM :func_compmgmt_check_acct_create
    call:inc func_log "INFO" "Creating %~1"

    :: Prompt for password -- admin and staff require a special prompt
    if "%~1" == "admin4" ( goto func_compmgmt_check_acct_admin )
    goto func_compmgmt_check_acct_password

    :func_compmgmt_check_acct_admin4
    call:inc func_check_password "admin_AAA" "admin" "admin_BBB"
    goto func_compmgmt_check_acct_netuser


    :func_compmgmt_check_acct_password
    call:inc func_check_password "%~1" "%~1"

    :: Set the password
    :func_compmgmt_check_acct_netuser
    setlocal DisableDelayedExpansion
    net user "%~1" "%password:~0,-1%" /add /active:Yes /passwordchg:yes >nul & endlocal
    wmic useraccount where name="%~1" set PasswordExpires=false >nul

    :func_compmgmt_check_acct_done
        exit /b 0


:: Writes BitLocker recovery instructions to the BitLocker recovery password file
:: $~1 is the path of the BitLocker recovery password file
:func_bitlocker_rp_info
    echo BitLocker Drive Encryption Recovery Key >> "%~1"
    echo %~nx0 - %date% %time%  >> "%~1"
    echo ---------------------------------------------------------------------- >> "%~1"
    echo To verify that this is the correct recovery key, compare the start of the following identifier with the identifier value displayed on your PC. >> "%~1"
    echo The identifier is the ID of the numerical password protector. The identifier number is a series of characters enclosed within curly braces {}. >> "%~1"
    echo. >> "%~1"
    echo If the above identifier matches the one displayed by your PC, then use the following key to unlock your drive. >> "%~1"
    echo The recovery key is the password of the numerical apssword protector. The password consists of eight six-digit numbers separated by hyphens. >> "%~1"
    echo. >> "%~1"
    echo If the above identifier doesn't match the one displayed by your PC, then this isn't the right key to unlock your drive. >> "%~1"
    echo Try another recovery key, or refer to https://go.microsoft.com/fwlink/?LinkID=260589 for additional assistance. >> "%~1"
    echo. >> "%~1"
    echo ---------------------------------------------------------------------- >> "%~1"
    echo. >> "%~1"
    exit /b 0


:: ============================================================================
:: ===== COMMON FUNCTIONS =====================================================
:: ============================================================================

:: Calls external function
:inc
    pushd %~dp0
    call "%PROGRAM_LIB_PATH%\__common.bat" %*
    popd & exit /b %errorlevel%
