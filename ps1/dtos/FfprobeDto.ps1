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
            "-show_entries", "stream=width,height,color_space,color_range,bit_rate,channels,sample_rate,handler_name",
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
        foreach ($stream in $jsonReplay.streams) {
            $handler = if ($stream.tags -and $stream.tags.PSObject.Properties.Name -contains "handler_name") {
                $stream.tags.handler_name.Trim()
            } else {
                ""
            }

            if ($handler -match "(?i)Video") {  # (?i) で大文字小文字無視
                $this.Video = [VideoInfo]::new()
                $this.Video.Width = if ($stream.width -match '^\d+$') { [int]$stream.width } else { $null }
                $this.Video.Height = if ($stream.height -match '^\d+$') { [int]$stream.height } else { $null }
                $this.Video.ColorSpace = $stream.color_space
                $this.Video.ColorRange = $stream.color_range
                $this.Video.BitRate = if ($stream.bit_rate -eq "N/A" -or -not ($stream.bit_rate -match '^\d+$')) { -1 } else { [int]$stream.bit_rate }
            } elseif ($handler -match "(?i)(Audio|Sound)") {  # Audio か Sound を検出
                $this.Audio = [AudioInfo]::new()
                $this.Audio.BitRate = if ($stream.bit_rate -eq "N/A" -or -not ($stream.bit_rate -match '^\d+$')) { -1 } else { [int]$stream.bit_rate }
                $this.Audio.Channels = if ($stream.channels -eq "N/A" -or -not ($stream.channels -match '^\d+$')) { -1 } else { [int]$stream.channels }
                $this.Audio.SampleRate = if ($stream.sample_rate -eq "N/A" -or -not ($stream.sample_rate -match '^\d+$')) { -1 } else { [int]$stream.sample_rate }
                $this.Audio.MaxVolume = if ($errReplay -match "max_volume: ([-\d.]+)") { [double]$matches[1] } else { 0 }
            } else {
                if (-not $this.Meta -and $stream.width) {
                    $this.Meta = [MetaInfo]::new()
                    $this.Meta.Width = if ($stream.width -match '^\d+$') { [int]$stream.width } else { $null }
                    $this.Meta.Height = if ($stream.height -match '^\d+$') { [int]$stream.height } else { $null }
                    $this.Meta.ColorSpace = $stream.color_space
                    $this.Meta.ColorRange = $stream.color_range
                }
            }
        }
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
}

class AudioInfo {
    [int]$BitRate
    [int]$Channels
    [int]$SampleRate
    [double]$MaxVolume
}

class MetaInfo {
    [int]$Width
    [int]$Height
    [string]$ColorSpace
    [string]$ColorRange
}
