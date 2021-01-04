@echo off

rem 引数チェック
if not "%1"=="start" (
    call :HELP_MSG
    exit /b 0
)

call :SET_AL_CUR_DIR
call :INIT_AL_HOME

exit /b

rem ------------------------------
rem コマンドを実行したカレントディレクトリを
rem 一時環境変数（_AL_CUR_DIR）に設定する
rem ------------------------------
:SET_AL_CUR_DIR
    setlocal enabledelayedexpansion
    for /f "usebackq" %%a in (`cd`) do (
        set _TMP_AL_CUR_DIR=%%a
    )
    endlocal && set _AL_CUR_DIR=%_TMP_AL_CUR_DIR%
exit /b

rem ------------------------------
rem alstroemeria のホームディレクトリを
rem 一時環境変数（_AL_DIR）に設定する
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
rem ヘルプ用メッセージ
rem ------------------------------
:HELP_MSG
    echo.
    echo alstroemeria の初期処理をまとめたもので各バッチから間接的に呼ばれます。
    echo ユーザが使用する事はありません。
    echo.
exit /b
