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
where ffprobe2 > nul 2>&1
if not "%ERRORLEVEL"=="0" (
    echo command cannot be found. Make sure ffmpeg is installed correctly. / command=[ffprobe]
    exit /b 1
)
echo main!
rem ------------------------------
rem �w���v�p���b�Z�[�W
rem ------------------------------
set FFPROBE_CMD=ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of default=nw=1 "%~1"


endlocal

exit /b

rem ------------------------------
rem �w���v�p���b�Z�[�W
rem ------------------------------
:HELP_MSG
    echo.
    echo �w�肵���摜�܂��͓���t�@�C���̉𑜓x��Ԃ�
    echo get-resolution [FILE]
    echo.
    echo ex)
    echo > get-resolution hoge.jpg
    echo width=640
    echo height=480
    echo.
exit /b
