@echo off
setlocal enabledelayedexpansion

rem ���������p�o�b�`���Ă�Ńz�[���f�B���N�g�����̏���ǂݍ���ł���
call "%~dp0init" start

rem �����`�F�b�N
if not "%1"=="list" (
    call :HELP_MSG
    exit /b 0
) else (
    set LAST_IMG_URL=%1
    for /f "usebackq tokens=1,2" %%a in (`dir /b`) do (
        set FILE_NAME=%%~na
        echo !FILE_NAME!
    )
)
endlocal

exit /b

rem ------------------------------
rem �w���v�p���b�Z�[�W
rem ------------------------------
:HELP_MSG
    echo.
    echo alstroemeria �ŗ��p�ł���R�}���h�ꗗ��\�����܂��B
    echo ahelp list
    echo.
exit /b
