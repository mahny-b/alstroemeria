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
where ffprobe2 > nul 2>&1
if not "%ERRORLEVEL"=="0" (
    echo command cannot be found. Make sure ffmpeg is installed correctly. / command=[ffprobe]
    exit /b 1
)
echo main!
rem ------------------------------
rem ヘルプ用メッセージ
rem ------------------------------
set FFPROBE_CMD=ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of default=nw=1 "%~1"


endlocal

exit /b

rem ------------------------------
rem ヘルプ用メッセージ
rem ------------------------------
:HELP_MSG
    echo.
    echo 指定した画像または動画ファイルの解像度を返す
    echo get-resolution [FILE]
    echo.
    echo ex)
    echo > get-resolution hoge.jpg
    echo width=640
    echo height=480
    echo.
exit /b
