@echo off
setlocal enabledelayedexpansion

rem ���������p�o�b�`���Ă�Ńz�[���f�B���N�g�����̏���ǂݍ���ł���
call "%~dp0init" start
rem echo _AL_HOME=!_AL_HOME!
rem echo _AL_CUR_DIR=!_AL_CUR_DIR!

rem �����`�F�b�N
if not "%1"=="list" (
    call :HELP_MSG
    exit /b 0
)

rem ------------------------------
rem ���C������
rem ------------------------------
cd /d "!_AL_HOME!"

for /f "usebackq" %%a in (`dir /b`) do (
    echo %%~na
)

cd /d "!_AL_CUR_DIR!"
endlocal

exit /b

rem ------------------------------
rem �w���v�p���b�Z�[�W
rem ------------------------------
:HELP_MSG
    echo.
    echo alstroemeria �ŗ��p�ł���R�}���h�ꗗ��\�����܂��B
    echo.
    echo usage^)
    echo     ^> ahelp list
    echo.
exit /b
