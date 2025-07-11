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
    48000, 44100, 32000, 24000, 22050, 16000, 12000, 11025, 8000

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

. $PSScriptRoot\dtos\FfprobeDto.ps1

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
指定フォルダの動画ファイルを一括で軽量化します。

usage)
    convert-to-lite-mp4 [オプション]

options)
    -i <INPUT_FOLDER>   入力フォルダを指定 (必須)
    -o <OUTPUT_FOLDER>  出力フォルダを指定 (省略可能、デフォルト: INPUT_FOLDER/conv)
    -r <RESOLUTION>     横幅解像度を指定 (省略可能、デフォルト: 1280)
                        HD:1280, HD+:1600, FHD:1920, 2K:2560, 4K:3840
    -b <BITRATE>        音声ビットレートを指定 (省略可能、デフォルト: 64000)
                        使用可能な値: 192000, 160000, 128000, 96000, 80000, 64000
    -s <SAMPLE_RATE>    音声サンプリングレートを指定 (省略可能、デフォルト: 16000)
                        使用可能な値: 48000, 44100, 32000, 22050, 16000
    -d                  変換後に元のファイルを削除 (省略可能)

ex)
    .\convert-to-lite-mp4 -i "C:\Videos" -o "C:\ConvertedVideos" -r 1920 -b 128000 -s 44100
    .\convert-to-lite-mp4 -i "D:\My Videos" -d

"@
}


# 解像度に応じたビットレート取得する
function Get-VideoBitrate {
    param (
        [int]$scale,
        [FfprobeDto]$mediaDto
    )

    $pixels = $scale * ($mediaDto.Video.Height / $mediaDto.Video.Width)
    $bitrate = switch ($pixels) {
        {$_ -ge 3840 * 2160} { 1000 * 1000 * 12; break }    # 4K
        {$_ -ge 2560 * 1440} { 1000 * 1000 * 8; break }     # 2K
        {$_ -ge 1920 * 1080} { 1000 * 1000 * 5; break }     # Full HD
        {$_ -ge 1280 * 720}  { 1000 * 1000 * 3; break }     # HD
        default { 1000 * 1000 * 2 }                         # SD以下
    }

    if ((0 -lt $mediaDto.Video.BitRate) -and ($mediaDto.Video.BitRate -lt $bitrate)) {
        $bitrate = [Math]::Floor($mediaDto.Video.BitRate / 8000) * 8000
    }

    $bufsize = $([Math]::Round($bitrate * 2))

    return [PSCustomObject]@{
        Bitrate = $bitrate
        Bufsize = $bufsize
    }
}


# 解像度からCRFを取得する
function Get-VideoCRF {
    param (
        [int]$scale,
        [FfprobeDto]$mediaDto
    )
    
    $pixels = $scale * ($mediaDto.Video.Height / $mediaDto.Video.Width)
    
    $crf = switch ($pixels) {
        {$_ -ge 3840 * 2160} { 26; break }
        {$_ -ge 2560 * 1440} { 24; break }
        {$_ -ge 1920 * 1080} { 22; break }
        {$_ -ge 1280 * 720}  { 20; break }
        default { 18 }
    }

    return $crf
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

    $mediaDto = [FfprobeDto]::new($input)
    Write-Host "------------------------------"
    Write-Host $mediaDto.ToString()
    Write-Host "------------------------------"

    # スケールフィルターの設定（回転チェック）
    $scaleFilter = if ([int]$mediaDto.Video.Width -lt [int]$mediaDto.Video.Height) {
        "transpose=2,scale=${videoScale}:-2"
    } else {
        "scale=${videoScale}:-2"
    }
    # 色情報が含まれない場合は、固定値を補う
    $isColorSpaceUnknown = ($mediaDto.Video.ColorSpace -eq "") -or ($mediaDto.Video.ColorRange -eq "")
    if ($isColorSpaceUnknown) {
        $scaleFilter += ",format=yuv420p"
    }

    # 音声ビットレートの取得
    $audioBitrate = if ([int]$mediaDto.Audio.BitRate -ge $audioBitrateThreshold) {
        $audioBitrateTarget
    } else {
        [Math]::Floor($mediaDto.Audio.BitRate / 8000) * 8000
    }

    # ビデオビットレートの取得
    $videoBitrateInfo = Get-VideoBitrate -scale $videoScale -mediaDto $mediaDto
    $videoCrf = Get-VideoCRF -scale $videoScale -mediaDto $mediaDto

    # 音声サンプリングレートの取得
    $audioSampleRate = $audioSampleRateThreshold
    if ((0 -lt $mediaDto.Audio.SampleRate) -and ($mediaDto.Audio.SampleRate -lt $audioSampleRate)) {
        $sampleRates = @(48000, 44100, 32000, 24000, 22050, 16000, 12000, 11025, 8000)

        # $mediaDto.Audio.SampleRate 以下の最も近い値を取得する。最後まで見つからない場合は最低値のまま使う
        for ($i = 0; $i -lt $sampleRates.Count; $i++) {
            if ($mediaDto.Audio.SampleRate -ge $sampleRates[$i]) {
                $audioSampleRate = $sampleRates[$i]
            }
        }
    }

    # 音量増幅率を取得
    $audioGain = [math]::Max(-0.5 - $mediaDto.Audio.MaxVolume, 0)
    Write-Host "変換中 (${currentFile}/${totalFiles}) / ""$($_.Name)"""

    if ($mediaDto.IsAV1() -and ("${GPU_ACCEL}" -ne "")) {
        # AV1かつハードウェアエンコード設定の場合: CPUエンコード（libx264）に切り替え
        $ffmpegArgs = @(
            "-i", "`"$input`""
            "-map_metadata", "0"
            "-vf", $scaleFilter
            "-c:v", "libx264"
            "-maxrate", $videoBitrateInfo.Bitrate
            "-bufsize", $videoBitrateInfo.Bufsize
            "-preset", "veryslow"
            "-c:a", $AUDIO_CODEC
            "-af", "volume=${audioGain}dB"
            "-b:a", $audioBitrate
            "-ar", $audioSampleRate
            "-b:v", $videoBitrateInfo.Bitrate
            "-y", "`"${outputFolder}\$($_.BaseName).${OUTPUT_FORMAT}`""
        )
    } else {
        # それ以外: 元の設定（GPUまたはCPU）を維持
        $ffmpegArgs = @(
            if ("${GPU_ACCEL}" -ne "" -and 0 -lt $mediaDto.Video.BitRate) { "-hwaccel", "$GPU_ACCEL" }
            "-i", "`"$input`""
            "-map_metadata", "0"
            "-vf", $scaleFilter
            "-c:v", $VIDEO_CODEC
            "-maxrate", $videoBitrateInfo.Bitrate
            "-bufsize", $videoBitrateInfo.Bufsize
            "-preset", $VIDEO_PRESET
            if ("${GPU_ACCEL}" -ne "" -and 0 -lt $mediaDto.Video.BitRate) { "-crf", $videoCrf }
            "-c:a", $AUDIO_CODEC
            "-af", "volume=${audioGain}dB"
            "-b:a", $audioBitrate
            "-ar", $audioSampleRate
            "-b:v", $videoBitrateInfo.Bitrate
            "-y", "`"${outputFolder}\$($_.BaseName).${OUTPUT_FORMAT}`""
        )
    }

    $processArgs = @{
        FilePath = "ffmpeg"
        ArgumentList = $ffmpegArgs
        NoNewWindow = $true
        PassThru = $true
        Wait = $true
    }

    # 変換処理実行
    Write-Host "ffmpeg options. / $($ffmpegArgs -join ' ')"
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
