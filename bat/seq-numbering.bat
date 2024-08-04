@echo off
setlocal enabledelayedexpansion

rem ���������p�o�b�`���Ă�Ńz�[���f�B���N�g�����̏���ǂݍ���ł���
call "%~dp0init" start

rem �����`�F�b�N
if not "%1"=="start" (
    call :HELP_MSG
    exit /b 0
) else (
    set LAST_IMG_URL=%1
    set IDX=1
    for /f "usebackq delims=" %%a in (`dir /b ^| findstr /i /r /c:"\.webp$" /c:"\.png$" /c:"\.jpg$" /c:"\.jpeg$"`) do (
        @REM set FILE_NAME=%%~na
        set FILE_NAME=00!IDX!
        set FILE_EXT=%%~xa
        set TARGET_FILE=%%a
        set RENAMED_FILE=!FILE_NAME:~-3!!FILE_EXT!

        set CMD=ren "!TARGET_FILE!" "!RENAMED_FILE!"
        echo !CMD!
        @REM !CMD!

        set /a IDX=!IDX! + 1

        @REM rem �ϊ��R�}���h��g�ݗ��ĂĎ��s����
        @REM set CONV_CMD=ffmpeg -i "!TARGET_FILE!" !CONV_SCALE! -loglevel warning -q 5 "!CONV_FILE!"
        @REM echo !CONV_CMD!
        @REM !CONV_CMD!

        @REM if "!ERRORLEVEL!"=="0" (
        @REM     timeout /t 1 > nul
        @REM     del /f "!TARGET_FILE!" > nul
        @REM     move /y "!CONV_FILE!" "!RENAMED_FILE!" > nul
        @REM ) else (
        @REM     echo skipped. / file=[!TARGET_FILE!]
        @REM )
    )
)
endlocal

exit /b


rem ------------------------------
rem �w���v�p���b�Z�[�W
rem ------------------------------
:HELP_MSG
    echo.
    echo �J�����g�f�B���N�g�����ɂ���t�@�C����ascii���ɘA�ԂŃ��l�[������
    echo.
    echo usage^)
    echo     ^> seq-numbering start
    echo.
exit /b
