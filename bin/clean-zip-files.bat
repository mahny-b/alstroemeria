@echo off
setlocal enabledelayedexpansion

rem 初期処理用バッチを呼んでホームディレクトリ等の情報を読み込んでおく
call "%~dp0init" start

rem 引数チェック
if /i not "%1"=="start" (
    call :HELP_MSG
    exit /b 0
) else (
    set INPUT_FILE=%~1
    set INPUT_EXT=%~x1
)

rem 前提コマンドチェック
where 7z > nul 2>&1
if not "%ERRORLEVEL%"=="0" (
    echo 7z コマンドが見つかりません。
    exit /b 1
)

for /f "usebackq delims=" %%a in (`dir /b ^| findstr /i /r /c:"\.zip$" /c:"\.7z$"`) do (
    set COMPRESSED_FILE=%%~a
    set CMD=7z d "!COMPRESSED_FILE!" "Thumbs.db" "__MACOSX" ".DS_Store" -r
    echo !CMD!
    !CMD! > nul
)

endlocal

exit /b 0

rem ------------------------------
rem ヘルプ用メッセージ
rem ------------------------------
:HELP_MSG
    echo.
    echo カレントディレクトリの圧縮ファイル（7z/zip）内から次のファイルやディレクトリを削除する
    echo     Thumbs.db
    echo     .DS_Store
    echo     .__MACOSX ^<DIR^>
    echo.
    echo usage^)
    echo     ^> clean-zip-files start
    echo.
exit /b
