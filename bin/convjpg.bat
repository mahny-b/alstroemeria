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
    for /f "usebackq" %%a in (`dir /b`) do (
        set FILE_NAME=%%~na
        set FILE_EXT=%%~xa
        set TARGET_FILE=%%a
        set CONV_FILE=convjpg_!FILE_NAME!.jpg
        set RENAMED_FILE=!FILE_NAME!.jpg

        call :IS_SUPPERTED_EXT "!FILE_EXT!"
        if "!ERRORLEVEL!"=="1" (
            rem �𑜓x���擾����
            for /f "usebackq tokens=1,2" %%b in (`get-resolution "!TARGET_FILE!"`) do (
                set _AL_WIDTH=%%b
                set _AL_HEIGHT=%%c
            )
            rem �𑜓x���t��HD�ȏ�Ȃ烊�T�C�Y�I�v�V���������
            set CONV_SCALE=
            if !_AL_HEIGHT! leq !_AL_WIDTH! (
                if 1920 leq !_AL_WIDTH! (
                    set CONV_SCALE=-vf "scale=1920:-1"
                )
            ) else (
                if 1920 leq !_AL_HEIGHT! (
                    set CONV_SCALE=-vf "scale=-1:1920"
                )
            )

            rem �ϊ��R�}���h��g�ݗ��ĂĎ��s����
            set CONV_CMD=ffmpeg -i "!TARGET_FILE!" !CONV_SCALE! -loglevel warning -q 5 "!CONV_FILE!"
            echo !CONV_CMD!
            !CONV_CMD!

            if "!ERRORLEVEL!"=="0" (
                timeout /t 1 > nul
                del /f "!TARGET_FILE!" > nul
                move /y "!CONV_FILE!" "!RENAMED_FILE!" > nul
            ) else (
                echo skipped. / file=[!TARGET_FILE!]
            )
        ) else (
            echo skipped. / file=[!TARGET_FILE!]
        )
    )
)
endlocal

exit /b

rem ------------------------------
rem �T�|�[�g����g���q���ǂ�����Ԃ�
rem [0] �g���q
rem ret: 0: �T�|�[�g���Ȃ� / 1: �`����
rem ------------------------------
:IS_SUPPERTED_EXT
    setlocal enabledelayedexpansion
    set ret=0
    if "%~1"==".jpg" (
        set ret=1
    ) else if "%~1"==".png" (
        set ret=1
    )
    endlocal && set ret=%ret%
exit /b %ret%

rem ------------------------------
rem �w���v�p���b�Z�[�W
rem ------------------------------
:HELP_MSG
    echo.
    echo �J�����g�f�B���N�g�����ɂ������`��jpg��windows�œǂ߂�jpg�ɕϊ�����
    echo.
    echo usage^)
    echo     ^> convjpg start
    echo.
exit /b
