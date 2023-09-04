:: from User_Setup_configure.bat

:: ===== CONFIGURE DEFAULT PROGRAMS =========================================== <TODO>

@REM call:inc func_progressbar_inc "Set Adobe Acrobat Reader and Chrome as default programs"

@REM :Set_Adobe_Acrobat_default
@REM call:inc func_msg ^
@REM     "This script will open Adobe Acrobat Reader. Please set Adobe Acrobat Reader as the default .pdf program." ^
@REM     "START" "Set Adobe Acrobat Reader as default" ^
@REM     "This can be done by selecting the Set as Default button near the right side of the window."

@REM start "" "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"

@REM :Set_Adobe_Acrobat_default_check
@REM %HEADER%
@REM echo Please set Adobe Acrobat Reader as the default .pdf program.
@REM echo.
@REM set /p "result=Type y and press enter once you have set the default program: "
@REM call:inc func_check_confirmation "!result!" ^
@REM     Set_Adobe_Acrobat_default_done ^
@REM     Set_Adobe_Acrobat_default_check
@REM goto !confirm_result!
@REM :Set_Adobe_Acrobat_default_done
@REM call:inc func_log "DONE" "Adobe Acrobat Reader set as default .pdf program"

@REM :Set_Chrome_default
@REM call:inc func_msg ^
@REM     "This script will open the Default Apps settings panel." ^
@REM     "START" "Set Chrome as default" ^
@REM     "When the settings panel opens, please change the default browser to be Chrome."

@REM explorer.exe shell:::{17cd9488-1228-4b2f-88ce-4298e93e0966} -Microsoft.DefaultPrograms\pageDefaultProgram

@REM :Set_Chrome_default_check
@REM %HEADER%
@REM echo Please set Chrome as the default browser.
@REM echo.
@REM set /p "result=Type y and press enter once you have set the default program: "
@REM call:inc func_check_confirmation "!result!" ^
@REM     Set_Chrome_default_done ^
@REM     Set_Chrome_default_check
@REM goto !confirm_result!
@REM :Set_Chrome_default_done
@REM call:inc func_log "DONE" "Chrome set as default browser"

@REM call:inc func_log "DONE" "Set Adobe Acrobat Reader and Chrome as default programs done"