:: DO NOT RUN THIS SCRIPT -- THIS SCRIPT IS NOT MEANT TO BE RUN
:: This script is a library to be used with the *_Setup_*.bat files

:: MACROS
if "%~1" == "" (
    goto stop_lib 
)
if "%~1" == "init" (
    goto set_macros
)
goto eval_func


:stop_lib
@echo off
cls
echo It appears that you have executed this script directly. This is a library 
echo file -- it should not be executed directly. Please launch a script like 
echo Laptop_Setup_prep.bat which supports being executed directly. We recommend
echo that you use a main menu script like Latitude_5320_Setup.bat.
call:func_end_script close 1


:set_macros
:: Header macro -- call to display a header
set "HEADER=cls & " 
set "HEADER=%HEADER%echo ============================================================================== & "
set "HEADER=%HEADER%echo ====                      Latitude 5320 Setup Script                      ==== & "
set "HEADER=%HEADER%echo ============================================================================== & "
set "HEADER=%HEADER%echo. &"
set "HEADER=%HEADER%call:inc func_progressbar &"
set "HEADER=%HEADER%echo."

:: Pause macro -- pauses the script until keypress, and then waits half a sec
set "PAUSE_UNTIL_DONE=echo Press space to continue the script. . . & "
set "PAUSE_UNTIL_DONE=%PAUSE_UNTIL_DONE%pause >nul &"
set "PAUSE_UNTIL_DONE=%PAUSE_UNTIL_DONE%timeout 1 >nul"

:: Default additional increment to add is 0 -- nonzero if sections are skipped or reversed
set "PROGRESSBAR_SKIP=0"

:: Path macros -- point to specific important paths for setups
set "OS_DRIVE=%SystemDrive%"
pushd %~dp0
set "DEFAULTS=%cd%\defaultapps.xml"
set "KMS_MSI=%cd%\KMS_MSI.msi"
popd

:: Date formatted like: 01-01-1970 -- this date is nice for filenames
set "FORMATTED_DATE=%date:~4,2%-%date:~7,2%-%date:~10,4%"
set "FORMATTED_TIME=%time:~0,2%-%time:~3,2%-%time:~6,2%"

:: Return code

:: Absolute paths to this program/script's libraries
pushd %~dp0\..
set "PROGRAM_LOG_PATH=%cd%\logs"
set "PROGRAM_INSTALLER_PATH=%cd%\installers"
set "PROGRAM_LIB_PATH=%cd%\lib"
set "PROGRAM_HASH_PATH=%cd%\lib\hashes"
popd
exit /b 0


:: Evaluate the function call %~1
:eval_func
:: init call headers:
:: %~0 init
:: included function call headers:
:: %~0 lib\__common.bat <function> <arg1> <arg2> ....

:: init argument for initializing macros only
if "%~1" == "init" ( exit /b 0 )

::switch into function
call:%~1 "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9" 
exit /b %errorlevel%

:: ============================================================================
:: ===== FUNCTION HEADERS =====================================================
:: ============================================================================

:: MESSAGE AND HEADER FUNCTIONS
:: func_msg                 <line1> <log_type> <log_msg> <line2> <line3>
:: func_log_init            <script_type>
:: func_log                 <log_type> <log_msg>

:: CHECK FUNCTIONS
:: func_check_admin
:: func_check_confirmation  <input> <success_label> <fail_label>
:: func_check_internet      <no_loop,VPN>
:: func_check_VPN
:: func_check_in_path       <name of executable>
:: func_check_if_exists     <path of executable>
:: func_check_msi_install   <path of log>
:: func_check_password      <hashfile name (no extension)> <password description)

:: PROGRESSBAR FUNCTIONS
:: func_progressbar_init    <path of parent script>
:: func_progressbar_inc     <section title>
:: func_progressbar

:: MISC FUNCTIONS
:: func_download_from_URL   <URL> <target name of file> <file extension>
:: func_end_script          <close,logoff,ask_restart> <exit_code>

:: INTERNAL FUNCTIONS       (for __commmon.bat internal use ONLY)
:: intfunc_getPassword      <password type>

:: ============================================================================
:: ===== MESSAGE AND HEADER FUNCTIONS =========================================
:: ============================================================================

:: Prints first argument, logs second argument, and then pauses
:: The strings should NOT have any reserved characters in them.
:: The reserved characters are: ^&()<>|
:: Arguments:
:: %~1 is the message that is to be printed
:: %~2 is the log type
:: %~3 is the log message
:: %~4 is an optional second line of messages
:: %~5 is an optional third line of messages
:: For readability, whenever this function is called, follow this format:
:: call:func_msg ^
::     "<msg>" ^
::     "<log_type>" "<log_message>" ^
::     "<2nd msg>" ^
::     "<3rd msg>"
:func_msg
    %HEADER%
    echo %~1

    if not "%~4" == "" ( echo %~4 )

    if not "%~5" == "" ( echo %~5 )

    call:func_log "%~2" "%~3"
    if not "%NOPAUSE%" == "enabled" ( %PAUSE_UNTIL_DONE% )

    exit /b 0


:: Creates log file if it doesn't exist
:: Side effect: finds service tag and adds it to the title of the current script
:: Returns %ser_tag% which is the service tag of the current device
:: Returns %LOGFILE% which the log file kept with the scripts in log directory
:: Returns %LOCAL_LOGFILE% which is logfile on local computer
:: Arguments:
:: %~1 is the type/name of the script
:func_log_init    
    :: Get Service Tag if not previously defined
    setlocal EnableDelayedExpansion
    if not defined ser_tag (
        wmic bios get serialnumber | findstr /v "SerialNumber" > laptop_setup_temp.txt
        set /p ser_tag= <laptop_setup_temp.txt
        del laptop_setup_temp.txt
        set "ser_tag=!ser_tag: =!"
    )
    endlocal & set "ser_tag=%ser_tag%"


    :: Get the name of the current user
    set "current_user="
    query user | findstr /v /c:USERNAME > laptop_setup_temp.txt
    for /f "tokens=1" %%i in (laptop_setup_temp.txt) do (
        set "current_user=%%i" & goto func_log_init_curr_user_found
    )
    :func_log_init_curr_user_found
    set "current_user=%current_user:~1%"
    del laptop_setup_temp.txt


    :: Append service tag to title
    title %CURR_SCRIPT% - %ser_tag%

    :: Initialize log file and log directory if they don't exist yet
    if not defined LOGFILE ( set "LOGFILE=%PROGRAM_LOG_PATH%\%ser_tag%.log" )
    set "curr_logfile=%LOGFILE%"

    if not exist "%PROGRAM_LOG_PATH%" ( mkdir "%PROGRAM_LOG_PATH%" )

    :: Add header to log file currently pointed at
    :func_log_init_log_header
    setlocal EnableDelayedExpansion
    if not exist "!curr_logfile!" (
        type nul > "!curr_logfile!"
    ) else (
        echo -------------------------------------------------------------------------------- >> "!curr_logfile!"
        echo. >> "!curr_logfile!"
    )
    echo ================================================================================ >> "!curr_logfile!"
    echo %~1 Script Log, %date% %time% >> "!curr_logfile!"
    echo ================================================================================ >> "!curr_logfile!"
    echo. >> "!curr_logfile!"
    endlocal

    :: Exit if no need for locallog
    if not "%LOCALLOG%" == "enabled" ( exit /b 0 )

    :: Exit if locallog has already been made
    if defined LOCAL_LOGFILE ( exit /b 0 )

    :: If LOCALLOG is enabled, then set the local log file and then go back to the log header routine

    :: Use username which is the username of the user running the script
    :: The locallog will ONLY be saved on admin accounts
    set "LOCAL_LOGFILE=%OS_DRIVE%\Users\%username%\Desktop\%ser_tag%.log"
    set "curr_logfile=%LOCAL_LOGFILE%"
    goto func_log_init_log_header

    :: safety exit
    exit /b 0


:: Logs event in log file. Also logs in local log file if it had been enabled
:: Note: Will only log in local log file (in user Desktop) if user is an admin
:: Arguments:
:: %~1 is the log type
:: %~2 is the log message
:func_log
    set "line=[%date% %time%] %CURR_SCRIPT% - %~1	%~2"
    echo %line% >> "%LOGFILE%"

    :: Will only write to locallog if user is an admin
    setlocal EnableDelayedExpansion
    if defined LOCAL_LOGFILE ( 
        net session 2>&1 | findstr /c:"There are no entries in the list." >nul
        if %errorlevel% == 0 ( endlocal & goto func_log_local_logfile )
    )
    exit /b 0

    :: for some reason, if you move the echo line into the if statement that
    :: points to this label, it crashes the script for Chrome update in
    :: Laptop_Setup_update.bat
    :: I guess it's a quirk of if-statement parsing when file outputs are
    :: involved, so it is best to keep this echo output separate from the if
    :func_log_local_logfile
    echo %line% >> %LOCAL_LOGFILE%
    exit /b 0

:: ============================================================================
:: ===== CHECK FUNCTIONS ======================================================
:: ============================================================================

:: Checks if script is being run as administrator shell
:: If so, then this script does nothing
:: If not, then this script creates a UAC prompt to elevate to admin in-place
:: If that UAC prompt is rejected, then the script closes
:func_check_admin
    call:func_progressbar_inc "Check Administrator Privileges"
    call:func_log "START" "Check Administrator"

    :: Check if script is run in administrator shell
    net session 2>&1 | findstr /c:"There are no entries in the list." >nul
    if not %errorLevel% == 0 (
        call:func_log "ERROR" "Administrator shell failed"
        %HEADER%
        echo This script will prompt you for administrator privileges.
        call:func_log "START" "Administrator shell prompt given"
        goto func_check_admin_prompt
    )

    :func_check_admin_done
    call:func_log "DONE" "Administrator shell verified"
    exit /b 0

    :func_check_admin_prompt
    :: All global variables from grandparent script, the "hyperscript", such as
    :: Latitude_5320_Setup.bat, should be re-initialized in ps_command below
    :: so that their value is preserved when the parent script is run again
    set "ps_command=            Start-Process cmd -ArgumentList '/c "
    set "ps_command=%ps_command%cd /d %CD% && "
    set "ps_command=%ps_command%set \"NOPAUSE=%NOPAUSE%\" && "
    set "ps_command=%ps_command%set \"LOCALLOG=%LOCALLOG%\" && "
    set "ps_command=%ps_command%set \"MAINMENU=%MAINMENU%\" && "
        set "ps_command=%ps_command%set \"TOC=n\" && "
    set "ps_command=%ps_command%%CURR_SCRIPT%' -Verb runas"

    powershell -command "%ps_command%" >nul

    if not %errorlevel% == 0 (
        goto func_check_admin_elev_fail
    )
    :: If administrator privileges gained in new shell, then exit this one
    exit 0

    :: If the user fails the UAC administrator privileges prompt
    :func_check_admin_elev_fail
    echo The administrator privileges elevation was unsuccessful.
    echo.
    call:func_end_script close 1

    :: safety exit
    exit 1
    

:: Checks if %~1 is some variant of y or yes to confirm some input prompt
:: Returns %confirm_result% which is the label that should be jumped to
:: Arguments:
:: %~1 is the input from the user
:: %~2 is the success label to be set to result (for jumping)
:: %~3 is the failure label to be set to result (for jumping)
:func_check_confirmation
    call:inc func_log "INFO" "User confirmation input is: %~1"
    call:func_check_confirmation_%~1 2>nul

    if not %errorlevel% == 0 ( 
        set "confirm_result=%~3"
    ) else (
        set "confirm_result=%~2"
    )

    exit /b 0

    :func_check_confirmation_y
    :func_check_confirmation_Y
    :func_check_confirmation_yes
    :func_check_confirmation_Yes
        exit /b 0


:: Checks if the internet connection is up and loops a check if not
:: Arguments:
:: %~1 is no_loop if you only want the function to check the internet function once
:func_check_internet
    call:func_progressbar_inc "Check Internet Connection"

    call:func_msg ^
        "Please connect to the internet (Wi-Fi or Ethernet)." ^
        "START" "The internet connection is pending" ^
        "This can be done from the Windows taskbar."

    :Check_Internet
    setlocal EnableDelayedExpansion
    %HEADER%
    echo Checking internet connection. . .
    echo.

    :: Ping Cloudflare, Google, and IANA to check connectivity
    echo Pinging Cloudflare (1.1.1.1). . .
    call:func_log "INFO" "ping 1.1.1.1"
    ping 1.1.1.1 -n 1 -w 2000 | findstr /c:"TTL" >nul
    if !errorlevel! == 0 ( goto Internet_Up )

    echo Pinging Google (8.8.8.8). . .
    call:func_log "INFO" "ping 8.8.8.8"
    ping 8.8.8.8 -n 1 -w 2000 | findstr /c:"TTL" >nul
    if !errorlevel! == 0 ( goto Internet_Up )

    echo Pinging OpenDNS (208.67.222.222). . .
    call:func_log "INFO" "ping example.com"
    ping 208.67.222.222 -n 1 -w 2000 | findstr /c:"TTL" >nul
    if !errorlevel! == 0 ( goto Internet_Up )
    

    :: Try curling webpages if it appears that ping doesn't work
    :: According to Ethan, sometimes VPN connections can block pings, but
    :: nearly all connections should allow HTTP GET requests
    echo.
    echo It appears that pinging doesn't work. We can try to use curl.
    echo.
    call:func_log "INFO" "Trying: where curl"
    where curl >nul
    if not !errorlevel! == 0 ( goto Curl_not_found )

    echo Performing: curl google.com
    call:func_log "INFO" "curl google.com"
    curl -f google.com >nul 2>&1
    if !errorlevel! == 0 ( goto Internet_Up )
    timeout /t 2 /nobreak >nul

    echo Performing: curl example.com
    call:func_log "INFO" "curl example.com"
    curl -f example.com >nul 2>&1
    if !errorlevel! == 0 ( goto Internet_Up )
    timeout /t 2 /nobreak >nul


    set "internet_down_msg=The connection is down. Please wait or try to reconnect."
    goto Internet_Down

    :Curl_not_found
    set "internet_down_msg=curl is not found. The connection is likely down. Please wait or try to reconnect"

    :Internet_Down
    set "internet_down_cont_msg="
    if "%~1" == "no_loop" ( 
        set "internet_down_cont_msg=The script will continue regardless of the connection status." 
    )
    call:func_msg ^
        "!internet_down_msg!" ^
        "ERROR" "Connection down: !internet_down_msg!" ^
        "%internet_down_cont_msg%"
    if not "%~1" == no_loop ( goto Check_Internet )
    exit /b 1

    :Internet_Up
    call:func_msg ^
        "The connection is up." ^
        "INFO" "The internet connection is up"
    
    exit /b 0


:: Checks if the VPN connection is up and loops a check if not
:func_check_VPN
    call:inc func_progressbar_inc "VPN Connection"

    call:inc func_msg ^
        "Please connect to VPN." ^
        "START" "Connection to VPN" ^
        "This can be done from the Windows taskbar."

    :VPN_Test
    call:inc func_log "START" "Verify VPN adapter exists"

    %HEADER%
    echo Checking VPN connection. . .
    echo.
    ipconfig /all | findstr /c:"VPN Adapter Name" >nul
    if %errorlevel% == 0 ( goto VPN_Up )

    call:inc func_msg ^
        "The VPN connection is down. Please wait or try to reconnect." ^
        "ERROR" "The VPN connection is down"
    goto VPN_Test

    :VPN_Up
    call:inc func_log "DONE" "The VPN connection is up"

    exit /b 0


:: Checks if an executable in PATH is accessible and exits script if not
:: Arguments:
:: %~1 is the name of the executable
:func_check_in_path
    call:func_log "START" "Check %~1 in PATH"
    where "%~1" >nul
    if %errorlevel% == 0 ( goto func_check_in_path_done )

    call:func_msg ^
        "ERROR: %~1 is not found. PATH may be damaged. The script will end now." ^
        "ERROR" "%~1 not found"
    call:func_end_script close

    :func_check_in_path_done
    call:func_log "DONE" "Check %~1 in PATH complete"

    exit /b 0


:: Checks if an executable exists given a directory.
:: If the executable does not exist, then the user can close the script
::     or continue the script
:: Returns %errorlevel% which is the errorlevel of the where command
:: Arguments:
:: %~1 is (the full path to) the file to be checked
:func_check_if_exists
    call:func_log "START" "Check %~1 exists"
    
    setlocal EnableDelayedExpansion
    set "pathname=%~dp1"

    :: Remove last backslash from path
    set "pathname=%pathname:~0,-1%"

    where "%pathname%":"%~nx1" >nul

    if %errorlevel% == 0 ( goto func_check_if_path_exists_done )

    call:func_msg ^
        "WARNING: The file %~nx1 does not exist in %pathname%" ^
        "ERROR" "%~1 does not exist"
    
    echo.
    echo Do you want to continue the script or exit now?
    echo WARNING: Continuing the script may lead to erroneous behavior. Do so at your own risk.
    set "result="
    set /p "result=Continue? (y/n, default: n)"
    call:func_check_confirmation "!result!" ^
        func_check_if_path_exists_done
        func_check_if_path_exists_exit
    set "errorlevel=1"
    goto %confirm_result%
    
    :func_check_if_path_exists_exit
    call:func_end_script close

    :func_check_if_path_exists_done
    call:func_log "DONE" "Check %~1 exists complete, errorlevel is %errorlevel%"

    exit /b %errorlevel%


:: Checks an .msi file log to see if the installation was successful
:: Also converts the log to be UTF-8 (msiexec generates UTF-16 by default)
:: This also supports the Dell Command Update logs
:: Arguments:
:: %~1 is the path to the log of the .msi file
:func_check_msi_install
    call:func_log "START" "Converting %~1 to UTF-8"
    type %~1 > templog.txt
    type templog.txt > %~1
    del templog.txt
    call:func_log "DONE" "Converting %~1 to UTF-8 done"

    call:func_log "START" "Check %~1 for successful installation"

    :: Check for successful finish message and goto done if they exist
    findstr /c:"Windows Installer installed the product" "%~1"
    if %errorlevel% == 0 ( goto func_check_msi_install_done )

    findstr /c:"Windows Installer reconfigured the product" "%~1"
    if %errorlevel% == 0 ( goto func_check_msi_install_done )

    :: Check if the log being checked is from Dell Command Update
    findstr /c:"dcu-cli.exe" "%~1"
    if %errorlevel% == 0 ( goto func_check_msi_install_dell )

    goto func_check_msi_install_fail

    :: Dell Command Update checks
    :func_check_msi_install_dell
    findstr /c:"The system has been updated" "%~1"
    if %errorlevel% == 0 ( goto func_check_msi_install_DCU_done )

    findstr /c:"No updates available" "%~1"
    if %errorlevel% == 0 ( goto func_check_msi_install_DCU_done )

    goto func_check_msi_install_DCU_fail

    :: .msi end messages
    :func_check_msi_install_done
    call:func_msg ^
        "The installation was successful." ^
        "DONE" "%~1 installation done" ^
        "The installation log can be found in %~1"
    exit /b 0

    :func_check_msi_install_fail
    call:func_msg ^
        "The installation has failed or the installation log file is empty." ^
        "ERROR" "%~1 installation failure" ^
        "The installation log can be found in %~1"
    exit /b 1

    :: DCU end messages
    :func_check_msi_install_DCU_done
    call:func_msg ^
        "Dell Command Update was successful." ^
        "DONE" "%~1 installation done" ^
        "The update log can be found in %~1"
    exit /b 0

    :func_check_msi_install_DCU_fail
    call:func_msg ^
        "Dell Command Update has failed." ^
        "ERROR" "%~1 installation failure" ^
        "The update log can be found in %~1"
    exit /b 1


:: Hashes a string input and then compares that to a password hash to see if
:: the string is the password. If the password is wrong, then the function tries again
:: The hashes used are SHA512
::
:: To generate the hash for a password, create a textfile named password.txt,
:: type the password, add a space after the password (on the same line), and then
:: type a newline (into password.txt). Then, run `certutil -hashfile password.txt SHA512`,
:: and you have the hash for the password. You should copy this has into a file with
:: the extension *.hash.
::
:: The extra space and newline in the hash process is needed because the echo
:: command adds the space and newline to the end of the content when outputting
:: to a file
::
:: Your password cannot have whitespace
::
:: Returns errorlevel of 0 if the password was correct
:: Returns errorlevel of 1 and a message if the password was incorrect
:: Arguments:
:: %~1 is the path to the hash of the correct password
:: %~2 is the password description
:: %~3 is an optional argument for a second hash that also indicates a correct password
:func_check_password
    :: Process the input password into a hash stored in a variable
    call:func_log "START" "Check %~2 password"

    :: Decrypt hashes
    call:func_check_if_exists "C:\Program Files\7-Zip\7z.exe"

    :: Get hashes password if it doesn't exist or if it is incorrect
    :: Then, extract the hash archive to %PROGRAM_HASH_PATH%
    pushd %PROGRAM_HASH_PATH%

    :func_check_password_decrypt_hashes
        if not defined hashes_password ( goto func_check_password_get_hash_password )

        :: Attempt a decryption with the hash password
        setlocal DisableDelayedExpansion
        "C:\Program Files\7-Zip\7z.exe" t hashes.7z -p"%hashes_password:~0,-1%" -aoa >nul 2>&1 & endlocal

        :: If password was correct, delete decrypted hash files and then check passwords
        if %errorlevel% == 0 ( goto func_check_password_input )

        :: If the hash decryption password input was wrong
        call:func_msg ^
            "The hash decryption password was incorrect." ^
            "ERROR" "Incorrect hash decryption password"
        set "hashes_password="
        goto func_check_password_decrypt_hashes

        :: Get hash decryption password
        :func_check_password_get_hash_password
        %HEADER%
        call:intfunc_getPassword "hash decryption"
        call:func_log "INFO" "Hash decryption password has been input"

        :: Get hash decryption password from file with user input
        set /p hashes_password=<temppass.txt

        :: Delete hash decryption password file
        del temppass.txt

        goto func_check_password_decrypt_hashes

    popd

    :: Get user password input, replace input chars with *
    :func_check_password_input
    %HEADER%
    call:intfunc_getPassword "%~2" "%~3"

    :: Convert user password input into hash, stored in inputhash
    echo.
    echo Checking password. . .
    certutil -hashfile temppass.txt SHA512 > tempcertutil.txt
    findstr /v /c:"hash" tempcertutil.txt > temphash.txt

    set /p inputhash=< temphash.txt
    set inputhash=%inputhash: =%

    set "password="
    set /p password=<temppass.txt 

    :: Delete input hash and pass files
    del temppass.txt & del tempcertutil.txt & del temphash.txt

    :: Decrypt hash files
    setlocal DisableDelayedExpansion
    "C:\Program Files\7-Zip\7z.exe" e hashes.7z -p"%hashes_password:~0,-1%" -aoa >nul 2>&1 & endlocal

    :: Set the correct hash
    set /p correcthash1=< "%PROGRAM_HASH_PATH%\%~1.hash"
    set correcthash1=%correcthash1: =%

    :: Set the second possible correct hash if given
    if "%~3" == "" ( goto func_check_password_del_hashes )
    set /p correcthash3=< "%PROGRAM_HASH_PATH%\%~3.hash"
    set correcthash3=%correcthash3: =%

    :: Delete decrypted hash files
    :func_check_password_del_hashes
    del /f "%PROGRAM_HASH_PATH%\*.hash"

    :: Compare hashes
    if "%inputhash%" == "%correcthash1%" ( goto func_check_password_correct )
    if "%inputhash%" == "%correcthash3%" ( goto func_check_password_correct )
    call:func_msg ^
        "The password was incorrect." ^
        "ERROR" "Incorrect password"
    goto func_check_password_input

    :: If the hash is correct
    :func_check_password_correct
    call:func_log "DONE" "Correct %~2 password"

    exit /b 0

:: ============================================================================
:: ===== PROGRESSBAR FUNCTIONS ================================================
:: ============================================================================

:: Initializes the progressbar variables that track the progressbar status
:: The function determines the size of the progressbar by analyzing the script
:: that it was called from, %~1, by counting the number of times that the
:: progressbar is incremented in that script.
::
:: This function also displays a table of contents with each entry being
:: a progressbar section -- the first argument of each func_progressbar_inc
:: call in the script
::
:: You MUST initialize and increment the progressbar before the first %HEADER% or func_msg call
::
:: Returns %progressbar% which is a temporary empty progressbar
:: Returns %progressbar_size% which is how many sections the progressbar has
:: Returns %progressbar_state% which is how many sections have been completed
:: Returns %progressbar_pending% which is how many sections there are left to complete
:: Arguments:
:: %~1 is the size of the progress bar
:func_progressbar_init
    call:func_log "START" "func_progressbar_init"

    set "progressbar_title=Progress Bar Initialization"
    set "progressbar=[. . . . . .]"

    %HEADER%
    echo Configuring header and progress bar. . .
    set /a "progressbar_size=0"

    :: append all known func_progressbar_inc calls in original file
    setlocal EnableDelayedExpansion
    set "tempfile_nc=laptop_setup_temp1.txt"
    set "tempfile_m=laptop_setup_temp2.txt"
    findstr /c:"::" /v "%~1" > %tempfile_nc%
    findstr /c:"call:inc func_check_admin" "%tempfile_nc%" > %tempfile_m%
    findstr /c:"call:inc func_check_internet" "%tempfile_nc%" >> %tempfile_m%
    findstr /c:"call:inc func_progressbar_inc" "%tempfile_nc%" >> %tempfile_m%

    :: Count the number of lines in the call compilation
    :: Also list a table of contents
    %HEADER%
    echo Table of Contents for %CURR_SCRIPT%:
    for /f "tokens=2,*" %%a in (%tempfile_m%) do ( 
        if "%%a" == "func_check_admin" (
            echo -  Check Admin
        )
        if "%%a" == "func_check_internet" (
            echo -  Check Internet
        )
        if "%%a" == "func_check_VPN" (
            echo -  Check VPN
        )
        if "%%a" == "func_progressbar_inc" (
            set "temptext=%%b"
            set "temptext=!temptext:~1, -1!"
            echo -  !temptext!
        )
        set /a "progressbar_size=!progressbar_size!+1"
    )
    echo.
    if "%TOC%" == "n" ( goto func_progressbar_init_TOC_done )
    if not "%NOPAUSE%" == "enabled" ( %PAUSE_UNTIL_DONE% )

    :: Done with displaying Table f Contents
    :func_progressbar_init_TOC_done
    del %tempfile_nc%
    del %tempfile_m%

    endlocal & set "progressbar_size=%progressbar_size%"

    call:func_log "INFO" "The progress bar is %progressbar_size%"

    :: Number of complete and incomplete segments (chars) in progressbar
    set "progressbar_state=-1"
    set "progressbar_pending=%progressbar_size%+1"

    call:func_log "DONE" "func_progressbar_init"

    exit /b 0


:: Increments the progress bar and sets a new title for the progress bar
:: Returns %progressbar% with a fully rendered progressbar indicating progress
:: Arguments:
:: %~1 is the title of the progress bar (can also be considered section title)
:: %PROGRESSBAR_SKIP% is the number of sections that should be skipped when
::   incrementing, which is 0 by default
:func_progressbar_inc
    set "progressbar_title=%~1"

    set /a "progressbar_state=%progressbar_state%+%PROGRESSBAR_SKIP%+1"
    set /a "progressbar_pending=%progressbar_pending%-%PROGRESSBAR_SKIP%-1"

    :: Generate progressbar and indicate completion numerically
    set "progressbar=["
    setlocal EnableDelayedExpansion
    if "%progressbar_size%" LSS 80 ( set "done=####" ) else ( set "done=##" )
    if "%progressbar_size%" LSS 80 ( set "pend=----" ) else ( set "pend=--" )

    for /l %%i in (1,1,%progressbar_state%) do set "progressbar=!progressbar!%done%"
    for /l %%i in (1,1,%progressbar_pending%) do set "progressbar=!progressbar!%pend%"
    set "progressbar=%progressbar%]  %progressbar_state%/%progressbar_size%"
    endlocal & set "progressbar=%progressbar%"

    call:func_log "--" "--"
    call:func_log "INFO" "===== %progressbar_title% =====" 
    call:func_log "--" "--"

    set "PROGRESSBAR_SKIP=0"
    exit /b 0


:: Prints the progress bar and returns. Usually only called by header macro
:func_progressbar
    if defined progressbar_title ( echo %progressbar_title% )
    echo.
    if defined progressbar ( echo %progressbar% )
    exit /b 0

:: ============================================================================
:: ===== MISC FUNCTIONS =======================================================
:: ============================================================================

:: Downloads a file from a URL to ..\installers\*
:: Returns %dl_filepath% which is an absolute path to the file that was downloaded
:: Arguments:
:: %~1 is the URL that hosts the file
:: %~2 is the target name for the downloaded file
:: %~3 is the file extension for the downloaded file (without the .)
:func_download_from_URL
    if not exist "%PROGRAM_INSTALLER_PATH%" ( 
        mkdir "%PROGRAM_INSTALLER_PATH%"
        call:inc func_log "INFO" "%PROGRAM_INSTALLER_PATH% made"
    )

    set "dl_filepath=%PROGRAM_INSTALLER_PATH%\%~2_%FORMATTED_DATE%.%~3"

    if not exist "%dl_filepath%" (
        call:inc func_log "START" "Download %dl_filepath%"

        echo The file %~2_%FORMATTED_DATE%.msi is being downloaded. . .
        certutil.exe -urlcache -split -f "%~1" "%dl_filepath%" >nul 2>&1
        echo The download has completed.

        call:inc func_log "DONE" "Download %dl_filepath% complete"
    )

    exit /b 0


:: Ends a script either by closing it, logging off, or restarting the device
:: If the script was spawned by a parent script that set the %MAINMENU% variable
:: as the path to the parent script, then the script will return to the parent
:: script instead of closing the cmd.exe window.
::
:: If the user is prompted to log off or restart and chooses not to, then 
:: the script will either close or return to parent.
::
:: Arguments:
:: %~1 is ask_restart only if the function should ask the user if they want to restart the computer
:: %~2 is the exit code that the program should exit with
:func_end_script
    echo The script will end now.
    echo.

    :: Switch to requested ending, default to close if unknown
    call:case_end_script_%~1 2>nul
    if not %errorlevel% == 0 ( call:case_end_script_close ) 
    goto end_script_return_mainmenu

    :case_end_script_close
        echo Press any key to close the script. . . & pause >nul
        exit /b 0

    :case_end_script_logoff
        set "prompt="
        set /p "prompt=Do you want to log out? (y/n, default: n): "
        if /I "%prompt%" == "y" ( 
            call:func_log "INFO" "Log out"
            logoff
        )
        exit /b 0
    
    :case_end_script_ask_restart
        set "prompt="
        set /p "prompt=Do you want to restart? (y/n, default: n): "
        if /I "%prompt%" == "y" ( 
            call:func_log "INFO" "System restart"
            shutdown /r /t 0
        )
        exit /b 0

    :end_script_return_mainmenu
        :: exit to main menu if exists, else close the script
        if "%MAINMENU%" == "" ( call:func_log "INFO" "Exiting script" & exit %~2 )
        call:func_log "INFO" "Returning to main menu"
        call %MAINMENU%

:: ============================================================================
:: ===== COMMON FUNCTIONS =====================================================
:: ============================================================================

:: Calls internal function as if it were an external function
:: We need this here so that the HEADER macro can be called from within the library
:: Inter-library function calls should not invoke this function
:inc
    call:%*
    exit /b 0

:: ============================================================================
:: ===== INTERNAL FUNCTIONS ===================================================
:: ============================================================================

:: Adopted from:
:: https://www.dostips.com/forum/viewtopic.php?p=33538#p33538

:: WARNING THIS FUNCTION IS EXTREMELY FRAGILE
:: YOUR PASSWORD CANNOT HAVE WHITESPACE
:: SOME SPECIAL CHARACTERS MAY NOT WORK AND MAY BREAK EVERYTHING

:: Subroutine to get the password and store it in temppass.txt
:: Arguments:
:: %~1 is the type of password (used in prompt)
:: %~2 indicates whether a second password exists -- any value means that a second valid password exists
:intfunc_getPassword
    setlocal enableextensions disabledelayedexpansion
    set "_password="

    rem We need a backspace to handle character removal
    for /f %%a in ('"prompt;$H&for %%b in (0) do rem"') do set "BS=%%a"

    rem Prompt the user 
    if "%~1" == "hash decryption" ( echo The hash decryption password is the same as the ADM admin password. )
    if not "%~2" == "" ( echo Either of the two valid passwords can be entered for this account. )
    set /p "=Please enter the %~1 password: " <nul 

:keyLoop
    rem retrieve a keypress
    set "key="
    for /f "delims=" %%a in ('xcopy /l /w "%~f0" "%~f0" 2^>nul') do if not defined key set "key=%%a"
    set "key=%key:~-1%"

    rem handle the keypress 
    rem     if No keypress (enter), then exit
    rem     if backspace, remove character from password and console
    rem     else add character to password and go ask for next one
    if defined key (
        if "%key%"=="%BS%" (
            if defined _password (
                set "_password=%_password:~0,-1%"
                setlocal enabledelayedexpansion & set /p "=!BS! !BS!"<nul & endlocal
            )
        ) else (
		    if "%key%"=="!" ( goto keyLoop_exclam )
            if "%key%"=="^" ( goto keyLoop_up )
            if "%key%"=="&" ( goto keyLoop_amper )
            if "%key%"=="%" ( goto keyLoop_perc )
            goto keyLoop_else

            :: Special ! case or else the ! gets eaten
            :keyLoop_exclam
                set "_password=%_password%^^!" 
                goto keyLoop_done

            :: Special ^ case or else the ^ gets eaten
            :keyLoop_up
                set "_password=%_password%^^^^"
                goto keyLoop_done

            :: Special & case
            :keyLoop_amper
                set "_password=%_password%^&"
                goto keyLoop_done

            :: Special % case
            :keyLoop_perc
                set "_password=%_password%%%"
                goto keyLoop_done

            :keyLoop_else
                set "_password=%_password%%key%" 

            :keyLoop_done
            set /p "=*"<nul
        )
        goto :keyLoop
    )
    echo(
    rem return password to caller
    if defined _password ( set "exitCode=0" ) else ( set "exitCode=1" )
    endlocal & echo %_password%> temppass.txt & exit /b %exitCode%
    :: WARNING: do not put a space to the left of the filepipe otherwise entire hash thing breaks