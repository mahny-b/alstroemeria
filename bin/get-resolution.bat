@echo off
setlocal enabledelayedexpansion

rem 初期処理用バッチを呼んでホームディレクトリ等の情報を読み込んでおく
call "%~dp0init" start

rem 引数チェック
if "%1"=="" (
    call :HELP_MSG
    exit /b 0
)
rem コマンドチェック
set CMD_WHERE=where ffprobe
%CMD_WHERE% > nul 2>&1
if not "%ERRORLEVEL%"=="0" (
    echo command cannot be found. Make sure ffmpeg is installed correctly. / command=[%CMD_WHERE%]
    exit /b 1
)

rem メイン処理
set CMD_FFPROBE=ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of default=nw=1 "%~1"

rem ffprobeコマンドのリプライはこんな感じになので、それを分解して1行に出す。呼び出し元はfor-usebackq tokensで取る
rem > ffprobe -v error ～ -of default=nw=1 "hoge.png"
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
rem ヘルプ用メッセージ
rem ------------------------------
:HELP_MSG
    echo.
    echo 指定した画像または動画ファイルの解像度を返す
    echo.
    echo usage^)
    echo     get-resolution [FILE]
    echo.
    echo option^)
    echo     FILE 画像または動画ファイル
    echo.
    echo ex^)
    echo     ^> get-resolution hoge.jpg
    echo     width=640
    echo     height=480
    echo.
exit /b
