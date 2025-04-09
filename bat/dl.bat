@echo off
setlocal enabledelayedexpansion

rem 引数チェック
if "%1"=="" (
    call :HELP_MSG
    exit /b 0
) else (
    set LAST_IMG_URL=%1
    for /f "usebackq tokens=1,2,3" %%a in (`powershell -c "'!LAST_IMG_URL!\' -replace '^(.+)/([0-9]+)\.([0-9a-zA-Z]+)', '$1 $2 $3 '"`) do (
        set BASE_URL=%%a
        set IMG_COUNT=%%b
        set IMG_EXT=%%c
    )
)

echo image count: !IMG_COUNT!

rem ダウンロード処理
for /l %%i in (1,1,!IMG_COUNT!) do (
    set idx=00%%i
    set DL_FILE=!BASE_URL!/!idx:~-3!.!IMG_EXT!
    set NEW_FILE=!idx:~-3!.!IMG_EXT!

    set WGET_CMD=powershell -c "wget -Uri '!DL_FILE!' -OutFile '!NEW_FILE!'"
    echo WGET_CMD=!WGET_CMD!
    !WGET_CMD!
)
endlocal

exit /b 0

rem ヘルプ用メッセージ
:HELP_MSG
    echo.
    echo 指定したURLから連番でファイルをダウンロードする
    echo dl [LAST_IMG_URL]
    echo.
    echo option^)
    echo     LAST_IMG_URL そのURLの最後のファイルURL
    echo.
    echo ex^) http://hoge.com/resources/1.jpg ～ http://hoge.com/10.jpg の10ファイルをダウンロードする
    echo     ^> dl http://hoge.com/resources/10.jpg
    echo.
exit /b
