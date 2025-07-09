class FfprobeDto {
    [string]$mediaFilePath
    [VideoInfo]$Video = $null
    [AudioInfo]$Audio = $null
    [MetaInfo]$Meta = $null

    <#
    コンストラクタ
    @param [string]$mediaFilePath - ffprobeで解析するメディア
    #>
    FfprobeDto([string]$mediaFilePath) {
        $this.mediaFilePath = $mediaFilePath
        $this.ParseFromFfprobeOutput()
    }

    <#
    ffprobeを実行し、Video, Audio, Meta情報を取得する
    #>
    hidden [void] ParseFromFfprobeOutput() {

        $ffprobeParams = @(
            "-v", "error",
            "-show_streams",
            "-show_entries", "stream=width,height,color_space,color_range,bit_rate,sample_rate,codec_type,disposition,codec_name",
            "-of", "json",
            """$($this.mediaFilePath)"""
        )

        $procArgs = @{
            FilePath = "ffprobe"
            ArgumentList = $ffprobeParams
            NoNewWindow = $true
            PassThru = $true
            Wait = $true
            RedirectStandardOutput = [System.IO.Path]::GetTempFileName()
            RedirectStandardError = [System.IO.Path]::GetTempFileName()
        }

        $proc = Start-Process @procArgs
        $replay = Get-Content -Path $procArgs.RedirectStandardOutput -Raw
        Write-Host "ffprobe output: $replay"

        $errReplay = Get-Content -Path $procArgs.RedirectStandardError -Raw
        if ($proc.ExitCode -ne 0) {
            throw "ffprobe failed with exit code $($proc.ExitCode). / file: $($this.mediaFilePath) / error: $errReplay"
        }
        Remove-Item -Path $procArgs.RedirectStandardOutput, $procArgs.RedirectStandardError -ErrorAction SilentlyContinue

        $jsonReplay = $replay | ConvertFrom-Json
        
        # ビデオストリームの候補を収集
        $videoStreams = @()
        $audioStreams = @()
        
        foreach ($stream in $jsonReplay.streams) {
            if ($stream.codec_type -eq "video") {
                $videoStreams += $stream
            } elseif ($stream.codec_type -eq "audio") {
                $audioStreams += $stream
            } else {
                # メタ情報処理（従来通り）
                if (-not $this.Meta -and $stream.width) {
                    $this.Meta = [MetaInfo]::new()
                    $this.Meta.Width = if ($stream.width -match '^\d+$') { [int]$stream.width } else { $null }
                    $this.Meta.Height = if ($stream.height -match '^\d+$') { [int]$stream.height } else { $null }
                    $this.Meta.ColorSpace = $stream.color_space
                    $this.Meta.ColorRange = $stream.color_range
                }
            }
        }

        # 最も高品質なビデオストリームを選択
        if ($videoStreams.Count -gt 0) {
            $bestVideoStream = $this.SelectBestVideoStream($videoStreams)
            
            $this.Video = [VideoInfo]::new()
            $this.Video.Width = if ($bestVideoStream.width -match '^\d+$') { [int]$bestVideoStream.width } else { $null }
            $this.Video.Height = if ($bestVideoStream.height -match '^\d+$') { [int]$bestVideoStream.height } else { $null }
            $this.Video.ColorSpace = $bestVideoStream.color_space
            $this.Video.ColorRange = $bestVideoStream.color_range
            $this.Video.BitRate = if ($bestVideoStream.bit_rate -eq "N/A" -or -not ($bestVideoStream.bit_rate -match '^\d+$')) { -1 } else { [int]$bestVideoStream.bit_rate }
            $this.Video.Codec = $bestVideoStream.codec_name
        }

        # 最も高品質なオーディオストリームを選択
        if ($audioStreams.Count -gt 0) {
            $bestAudioStream = $this.SelectBestAudioStream($audioStreams)
            
            $this.Audio = [AudioInfo]::new()
            $this.Audio.BitRate = if ($bestAudioStream.bit_rate -eq "N/A" -or -not ($bestAudioStream.bit_rate -match '^\d+$')) { -1 } else { [int]$bestAudioStream.bit_rate }
            $this.Audio.SampleRate = if ($bestAudioStream.sample_rate -eq "N/A" -or -not ($bestAudioStream.sample_rate -match '^\d+$')) { -1 } else { [int]$bestAudioStream.sample_rate }
            $this.Audio.MaxVolume = if ($errReplay -match "max_volume: ([-\d.]+)") { [double]$matches[1] } else { 0 }
        }
    }

    <#
    最も高品質なビデオストリームを選択する
    優先順位：
    1. attached_pic (サムネイル) を除外
    2. 解像度（幅×高さ）が最も高い
    3. ビットレートが最も高い
    4. defaultストリーム
    #>
    hidden [object] SelectBestVideoStream([array]$videoStreams) {
        # attached_pic（サムネイル）を除外
        $mainVideoStreams = $videoStreams | Where-Object { 
            -not ($_.disposition -and $_.disposition.attached_pic -eq 1)
        }
        
        # メインビデオストリームがない場合は全てから選択
        if ($mainVideoStreams.Count -eq 0) {
            $mainVideoStreams = $videoStreams
        }
        
        # 1つしかない場合はそれを返す
        if ($mainVideoStreams.Count -eq 1) {
            return $mainVideoStreams[0]
        }
        
        # 複数ある場合は品質で選択
        $bestStream = $mainVideoStreams[0]
        
        foreach ($stream in $mainVideoStreams) {
            # 解像度で比較（幅×高さ）
            $currentResolution = if ($stream.width -match '^\d+$' -and $stream.height -match '^\d+$') {
                [int]$stream.width * [int]$stream.height
            } else { 0 }
            
            $bestResolution = if ($bestStream.width -match '^\d+$' -and $bestStream.height -match '^\d+$') {
                [int]$bestStream.width * [int]$bestStream.height
            } else { 0 }
            
            if ($currentResolution -gt $bestResolution) {
                $bestStream = $stream
                continue
            }
            
            # 解像度が同じ場合はビットレートで比較
            if ($currentResolution -eq $bestResolution) {
                $currentBitrate = if ($stream.bit_rate -match '^\d+$') { [int]$stream.bit_rate } else { 0 }
                $bestBitrate = if ($bestStream.bit_rate -match '^\d+$') { [int]$bestStream.bit_rate } else { 0 }
                
                if ($currentBitrate -gt $bestBitrate) {
                    $bestStream = $stream
                    continue
                }
                
                # ビットレートも同じ場合はdefaultストリームを優先
                if ($currentBitrate -eq $bestBitrate) {
                    if ($stream.disposition -and $stream.disposition.default -eq 1) {
                        $bestStream = $stream
                    }
                }
            }
        }
        
        return $bestStream
    }

    <#
    最も高品質なオーディオストリームを選択する
    優先順位：
    1. サンプリングレートが最も高い
    2. ビットレートが最も高い
    3. defaultストリーム
    #>
    hidden [object] SelectBestAudioStream([array]$audioStreams) {
        # 1つしかない場合はそれを返す
        if ($audioStreams.Count -eq 1) {
            return $audioStreams[0]
        }
        
        # 複数ある場合は品質で選択
        $bestStream = $audioStreams[0]
        
        foreach ($stream in $audioStreams) {
            # サンプリングレートで比較
            $currentSampleRate = if ($stream.sample_rate -match '^\d+$') { [int]$stream.sample_rate } else { 0 }
            $bestSampleRate = if ($bestStream.sample_rate -match '^\d+$') { [int]$bestStream.sample_rate } else { 0 }
            
            if ($currentSampleRate -gt $bestSampleRate) {
                $bestStream = $stream
                continue
            }
            
            # サンプリングレートが同じ場合はビットレートで比較
            if ($currentSampleRate -eq $bestSampleRate) {
                $currentBitrate = if ($stream.bit_rate -match '^\d+$') { [int]$stream.bit_rate } else { 0 }
                $bestBitrate = if ($bestStream.bit_rate -match '^\d+$') { [int]$bestStream.bit_rate } else { 0 }
                
                if ($currentBitrate -gt $bestBitrate) {
                    $bestStream = $stream
                    continue
                }
                
                # ビットレートも同じ場合はdefaultストリームを優先
                if ($currentBitrate -eq $bestBitrate) {
                    if ($stream.disposition -and $stream.disposition.default -eq 1) {
                        $bestStream = $stream
                    }
                }
            }
        }
        
        return $bestStream
    }

    [bool] IsAV1() {
        return $this.Video -and $this.Video.Codec -eq "av1"
    }

    [string] ToString() {
        return $this | ConvertTo-Json
    }
}

class VideoInfo {
    [int]$Width
    [int]$Height
    [string]$ColorSpace
    [string]$ColorRange
    [int]$BitRate
    [string]$Codec
}

class AudioInfo {
    [int]$BitRate
    [int]$SampleRate
    [double]$MaxVolume
}

class MetaInfo {
    [int]$Width
    [int]$Height
    [string]$ColorSpace
    [string]$ColorRange
}
