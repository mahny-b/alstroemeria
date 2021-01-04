@echo off

rem �����`�F�b�N
if not "%1"=="start" (
    call :HELP_MSG
    exit /b 0
)

call :SET_AL_CUR_DIR
call :INIT_AL_HOME

exit /b

rem ------------------------------
rem �R�}���h�����s�����J�����g�f�B���N�g����
rem �ꎞ���ϐ��i_AL_CUR_DIR�j�ɐݒ肷��
rem ------------------------------
:SET_AL_CUR_DIR
    setlocal enabledelayedexpansion
    for /f "usebackq" %%a in (`cd`) do (
        set _TMP_AL_CUR_DIR=%%a
    )
    endlocal && set _AL_CUR_DIR=%_TMP_AL_CUR_DIR%
exit /b

rem ------------------------------
rem alstroemeria �̃z�[���f�B���N�g����
rem �ꎞ���ϐ��i_AL_DIR�j�ɐݒ肷��
rem ------------------------------
:INIT_AL_HOME
    setlocal enabledelayedexpansion
    if not defined _TMP_AL_DIR (
        set _TMP_AL_HOME=%~dp0
        set _TMP_AL_HOME=!_TMP_AL_HOME:~0,-1!
    )
    endlocal && set _AL_DIR=%_TMP_AL_DIR%
exit /b

rem ------------------------------
rem �w���v�p���b�Z�[�W
rem ------------------------------
:HELP_MSG
    echo.
    echo alstroemeria �̏����������܂Ƃ߂����̂Ŋe�o�b�`����ԐړI�ɌĂ΂�܂��B
    echo ���[�U���g�p���鎖�͂���܂���B
    echo.
exit /b
