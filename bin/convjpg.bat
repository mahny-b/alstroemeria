@echo off
setlocal enabledelayedexpansion

rem 初期処理用バッチを呼んでホームディレクトリ等の情報を読み込んでおく
call "%~dp0init" start

rem 引数チェック
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
            rem 解像度を取得する
            for /f "usebackq tokens=1,2" %%b in (`get-resolution "!TARGET_FILE!"`) do (
                set _AL_WIDTH=%%b
                set _AL_HEIGHT=%%c
            )
            rem 解像度がフルHD以上ならリサイズオプションを作る
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

            rem 変換コマンドを組み立てて実行する
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
rem サポートする拡張子かどうかを返す
rem [0] 拡張子
rem ret: 0: サポートしない / 1: ～する
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
rem ヘルプ用メッセージ
rem ------------------------------
:HELP_MSG
    echo.
    echo カレントディレクトリ内にある特殊形式jpgをwindowsで読めるjpgに変換する
    echo convjpg start
    echo.
exit /b
