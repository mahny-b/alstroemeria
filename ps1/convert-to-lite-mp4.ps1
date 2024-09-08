<#
.SYNOPSIS
    動画ファイル一括軽量化スクリプト

.DESCRIPTION
    任意のフォルダ配下にある動画ファイルを、そこそこの品質に落として軽量化変換する。
    また、縦長の動画は、反時計回りに90度回転させます。
    本スクリプトは「ffmpeg」を使用する。予めインストールし、Windowsパスを通して置く事
    あなたの環境に合わせて、「変換設定の定数」のセクションを修正して下さい。

.PARAMETER i
    入力フォルダ（相対パス or 絶対パス）

.PARAMETER r
    横幅解像度（初期値1280）
    HD:1280, HD+:1600, FHD:1920, 2K:2560, 4K:3840

.PARAMETER b
    ビットレート（accで使えるものは以下の通り）
    192000, 160000, 128000, 96000, 80000, 64000

.PARAMETER s
    サンプリングレート（accで使えるものは以下の通り）
    48000, 44100, 32000, 22050, 16000

.PARAMETER o
    出力フォルダ（相対パス or 絶対パス。存在しない場合は新規に作成する。未指定時は、入力フォルダ直下に「conv」を作成する）

.NOTES
    author: mahny

#>
param (
    [string]$i,
    [int]$r = 1280,
    [int]$b = 64000,
    [int]$s = 16000,
    [string]$o,
    [switch]$d
)


#----------------------------
# 変換設定の定数
#----------------------------
# 本スクリプトで変換対象にするファイル拡張子の正規表現パターン
$INPUT_REGEXP = "\.(mp4|mov|mpg|mpeg|avi|mkv|webm|flv|3gp)$"

# 変換後のファイル拡張子
$OUTPUT_FORMAT = "mp4"

# GPUアクセラレータ。グラボを積んでる人は変えてみて。対象がない場合は空文字（CPU利用）にする事。
# NO USE:(空文字), nVIDIA:cuda, AMD:amf, Intel:qsv
# $GPU_ACCEL = ""
$GPU_ACCEL = "cuda"

# ビデオコーデック
# CPU:libx264, nVIDIA:h264_nvenc, AMD:h264_amf, Intel:h264_qsv
# $VIDEO_CODEC = "libx264"
$VIDEO_CODEC = "h264_nvenc"

# 汎用で指定できるプリセット: (エンコ速度重視⇐) fast,medium,slow,veryslow （⇒ファイルサイズ重視）
# nDIVIA専用プリセット: default, hp(高速縁故), hq(高品質), bd(非推奨), ll(非推奨), llhp(非推奨), llhq(非推奨), lossless(非推奨), losslesshq(非推奨)
# $VIDEO_PRESET = "veryslow"
$VIDEO_PRESET = "hq"

# 音声コーデック
$AUDIO_CODEC = "aac"


#----------------------------
# 準定数定義（触らなくていい）
#----------------------------
# ビデオスケール（変換後の動画横幅）
$videoScale = $r

# mahnyはバカ耳なので低音質設定です。我慢できない人は適宜上げてください。
# ビットレート
# 192000, 160000, 128000, 96000, 80000, 64000
$audioBitrateThreshold = $b
$audioBitrateTarget = "$([Math]::Floor(${audioBitrateThreshold} / 1000))k"

# サンプリングレート
# 48000, 44100, 32000, 22050, 16000
$audioSampleRateThreshold = $s

#----------------------------
# 関数定義
#----------------------------

# ヘルプを表示する
function Show-Help {
    Write-Host @"
指定フォルダの動画ファイルを、一括で軽量化します。

usage)
    convert-to-lite-mp4 -i INPUT_FOLDER -o OUTPUT_FOLDER

options)
    -i     入力フォルダ
    -o     出力フォルダ

"@
}


# 解像度に応じたビットレート取得する
function Get-VideoBitrate {
    param (
        [int]$width,
        [int]$height
    )
    $pixels = $width * $height
    $bitrate = switch ($pixels) {
        {$_ -ge 3840 * 2160} { "16M"; break } # 4K
        {$_ -ge 2560 * 1440} { "10M"; break } # 2K
        {$_ -ge 1920 * 1080} { "6M"; break }  # Full HD
        {$_ -ge 1280 * 720}  { "4M"; break }  # HD
        default { "2M" }                      # SD以下
    }
    
    if ($bitrate -notmatch '^\d+M$') {
        throw "Invalid bitrate format: $bitrate"
    }

    $bitrateValue = [int]($bitrate.TrimEnd('M'))
    $bufsize = "$([Math]::Round($bitrateValue * 2))M"

    return [PSCustomObject]@{
        Bitrate = $bitrate
        Bufsize = $bufsize
    }
}


# 解像度からCRFを取得する
function Get-VideoCRF {
    param (
        [int]$width,
        [int]$height
    )
    
    $pixels = $width * $height
    
    if ($pixels -ge 2073600) {  # 1920x1080以上
        return 27
    } elseif ($pixels -ge 921600) {  # 1280x720以上
        return 26
    } else {
        return 25
    }
}


# 指定したプロセスを停止する。停止成功、または停止済みの場合はtrueを返す
function Stop-FfmpegProcess {
    param (
        [int]$ProcessId,
        [int]$TimeoutSeconds = 3
    )
    $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if (-not $process) {
        Write-Host "ffmpegプロセス(PID: $ProcessId)は既に停止済みです。"
        return $true
    }
    
    # 通常の終了を待つ
    $process | Wait-Process -Timeout $TimeoutSeconds -ErrorAction SilentlyContinue
    if (!$process.HasExited) {
        # Terminateを試みる
        Write-Host "ffmpegプロセス(PID: $ProcessId)の終了をします。"
        $process.CloseMainWindow()
        $process | Wait-Process -Timeout $TimeoutSeconds -ErrorAction SilentlyContinue
        
        if (!$process.HasExited) {
            # 強制終了
            Write-Host "ffmpegプロセス(PID: $ProcessId)を強制終了します。"
            Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
            $process | Wait-Process -Timeout 2 -ErrorAction SilentlyContinue
        }
    }
    $ret = $process.HasExited
    Write-Host "ffmpegプロセス(PID: $ProcessId)を" + ($ret ? "終了しました。" : "終了出来ませんでした。")
    return $ret
}


# 指定した動画ファイルを削除する
function Remove-ConvertedVideo {
    param (
        [string]$file
    )
    try {
        [System.IO.File]::Delete($file)
        Write-Host "ファイルを削除しました: ""$file"""
        return $true
    }
    catch {
        Write-Host "削除に失敗しました: ""$file"""
        Write-Host "エラー: $($_.Exception.Message)"
        return $false
    }
}


#----------------------------
# メイン処理
#----------------------------
if (-not $i) {
    Show-Help
    exit
}

$inputFolder = Resolve-Path $i
$outputFolder = if (-not $o) {
    $tempFolder = Join-Path -Path "$inputFolder" -ChildPath "conv"
    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($tempFolder)
} else {
    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($o)
}

if (-not (Test-Path $inputFolder)) {
    Write-Host "入力フォルダが存在しません: $inputFolder"
    exit
}
Write-Host "入力フォルダ: $inputFolder"
Write-Host "出力フォルダ: $outputFolder"


if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# 処理するファイル数を確認
$files = Get-ChildItem -Path $inputFolder | Where-Object { $_.Extension -match "${INPUT_REGEXP}" }
$totalFiles = $files.Count
$currentFile = 0
Write-Host "検出されたファイル数: $totalFiles"

# 変換処理
$files | ForEach-Object {
    $currentFile++
    $input = $_.FullName
    $output = Join-Path $outputFolder $_.Name
    
    $videoInfo = ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 $input
    $width, $height = $videoInfo.Split(',')

    # スケールフィルターの設定
    $scaleFilter = if ([int]$width -lt [int]$height) {
        "transpose=2,scale=${videoScale}:-2"
    } else {
        "scale=${videoScale}:-2"
    }

    $audioRate = (ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 $input)
    $audioBitrate = if ([int]$audioRate -ge $audioBitrateThreshold) { $audioBitrateTarget } else { $audioRate }
    
    # ビデオビットレートの取得
    $videoBitrateInfo = Get-VideoBitrate -width $width -height $height
    $videoCrf = Get-VideoCRF -width $width -height $height

    $audioSampleRate = (ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 $input)
    $audioSampleRate = if ([int]$audioSampleRate -gt $audioSampleRateThreshold) { "${audioSampleRateThreshold}" } else { $audioSampleRate }
    
    Write-Host "変換中 (${currentFile}/${totalFiles}) / ""$($_.Name)"""
    $ffmpegArgs = @(
        if (${GPU_ACCEL} -ne "") { "-hwaccel", $GPU_ACCEL }
        "-i", "`"$input`""
        "-vf", $scaleFilter
        "-c:v", $VIDEO_CODEC
        "-maxrate", $videoBitrateInfo.Bitrate
        "-bufsize", $videoBitrateInfo.Bufsize
        "-preset", $VIDEO_PRESET
        if (${GPU_ACCEL} -ne "") { "-crf", $videoCrf }
        "-c:a", $AUDIO_CODEC
        "-b:a", $audioBitrate
        "-ar", $audioSampleRate
        "-y", "`"${outputFolder}\$($_.BaseName).${OUTPUT_FORMAT}`""
    )

    $processArgs = @{
        FilePath = "ffmpeg"
        ArgumentList = $ffmpegArgs
        NoNewWindow = $true
        PassThru = $true
        Wait = $true
    }

    # 変換処理実行
    Write-Host "command. / $ffmpegPath $($ffmpegArgs -join ' ')"
    $process = Start-Process @processArgs

    if ($process.ExitCode -ne 0) {
        Write-Error "変換に失敗しました / ""$($_.Name)"""
        exit 1
    }

    Write-Host "変換が成功しました / ""$($_.Name)"""
    if ($d) {
        if (-not (Stop-FfmpegProcess -ProcessId $process.Id)) {
            Write-Error "ffmpegプロセスの終了に失敗しました: file=[""$($_.Name)""], pid=[$($process.Id)]"
            exit 1
        }
        if (-not (Remove-ConvertedVideo -file $input)) {
            Write-Error "ファイルの削除に失敗しました: ""$($_.Name)"""
            exit 1
        }
    }
}

Write-Host "変換が完了しました。"
