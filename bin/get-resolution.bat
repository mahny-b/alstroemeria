@echo off
setlocal enabledelayedexpansion

rem ���������p�o�b�`���Ă�Ńz�[���f�B���N�g�����̏���ǂݍ���ł���
call "%~dp0init" start

rem �����`�F�b�N
if "%1"=="" (
    call :HELP_MSG
    exit /b 0
)
rem �R�}���h�`�F�b�N
set CMD_WHERE=where ffprobe
%CMD_WHERE% > nul 2>&1
if not "%ERRORLEVEL%"=="0" (
    echo command cannot be found. Make sure ffmpeg is installed correctly. / command=[%CMD_WHERE%]
    exit /b 1
)

rem ���C������
set CMD_FFPROBE=ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of default=nw=1 "%~1"

rem ffprobe�R�}���h�̃��v���C�͂���Ȋ����ɂȂ̂ŁA����𕪉�����1�s�ɏo���B�Ăяo������for-usebackq tokens�Ŏ��
rem > ffprobe -v error �` -of default=nw=1 "hoge.png"
rem width=3840
rem height=2140
for /f "usebackq" %%a in (`!CMD_FFPROBE!`) do (
    set REPLY=%%a
    echo "!REPLY!" | findstr "width" > nul 2>&1
    set IS_WIDTH=!ERRORLEVEL!

    echo "!REPLY!" | findstr "height" > nul 2>&1
    set IS_HEIGHT=!ERRORLEVEL!

    if "!IS_WIDTH!"=="0" (
        set _AL_WIDTH=!REPLY:~6!
    ) else if "!IS_HEIGHT!"=="0" (
        set _AL_HEIGHT=!REPLY:~7!
    )
)
echo !_AL_WIDTH! !_AL_HEIGHT!
endlocal

exit /b 0

rem ------------------------------
rem �w���v�p���b�Z�[�W
rem ------------------------------
:HELP_MSG
    echo.
    echo �w�肵���摜�܂��͓���t�@�C���̉𑜓x��Ԃ�
    echo.
    echo usage^)
    echo     get-resolution [FILE]
    echo.
    echo option^)
    echo     FILE �摜�܂��͓���t�@�C��
    echo.
    echo ex^)
    echo     ^> get-resolution hoge.jpg
    echo     width=640
    echo     height=480
    echo.
exit /b
