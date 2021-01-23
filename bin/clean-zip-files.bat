@echo off
setlocal enabledelayedexpansion

rem ���������p�o�b�`���Ă�Ńz�[���f�B���N�g�����̏���ǂݍ���ł���
call "%~dp0init" start

rem �����`�F�b�N
if /i not "%1"=="start" (
    call :HELP_MSG
    exit /b 0
) else (
    set INPUT_FILE=%~1
    set INPUT_EXT=%~x1
)

rem �O��R�}���h�`�F�b�N
where 7z > nul 2>&1
if not "%ERRORLEVEL%"=="0" (
    echo 7z �R�}���h��������܂���B
    exit /b 1
)

for /f "usebackq delims=" %%a in (`dir /b ^| findstr /i /r /c:"\.zip$" /c:"\.7z$"`) do (
    set COMPRESSED_FILE=%%~a
    set CMD=7z d "!COMPRESSED_FILE!" "Thumbs.db" "__MACOSX" ".DS_Store" -r
    echo !CMD!
    !CMD! > nul
)

endlocal

exit /b 0

rem ------------------------------
rem �w���v�p���b�Z�[�W
rem ------------------------------
:HELP_MSG
    echo.
    echo �J�����g�f�B���N�g���̈��k�t�@�C���i7z/zip�j�����玟�̃t�@�C����f�B���N�g�����폜����
    echo     Thumbs.db
    echo     .DS_Store
    echo     .__MACOSX ^<DIR^>
    echo.
    echo usage^)
    echo     ^> clean-zip-files start
    echo.
exit /b
