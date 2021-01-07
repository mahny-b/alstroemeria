@echo off
setlocal enabledelayedexpansion

rem 初期処理用バッチを呼んでホームディレクトリ等の情報を読み込んでおく
call "%~dp0init" start
rem echo _AL_HOME=!_AL_HOME!
rem echo _AL_CUR_DIR=!_AL_CUR_DIR!

rem 引数チェック
if not "%1"=="list" (
    call :HELP_MSG
    exit /b 0
)

rem ------------------------------
rem メイン処理
rem ------------------------------
cd /d "!_AL_HOME!"

for /f "usebackq" %%a in (`dir /b`) do (
    echo %%~na
)

cd /d "!_AL_CUR_DIR!"
endlocal

exit /b

rem ------------------------------
rem ヘルプ用メッセージ
rem ------------------------------
:HELP_MSG
    echo.
    echo alstroemeria で利用できるコマンド一覧を表示します。
    echo.
    echo usage^)
    echo     ^> ahelp list
    echo.
exit /b
