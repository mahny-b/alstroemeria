@echo off
setlocal enabledelayedexpansion

rem 初期処理用バッチを呼んでホームディレクトリ等の情報を読み込んでおく
call "%~dp0init" start

rem 引数チェック
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
rem ヘルプ用メッセージ
rem ------------------------------
:HELP_MSG
    echo.
    echo alstroemeria で利用できるコマンド一覧を表示します。
    echo ahelp list
    echo.
exit /b
