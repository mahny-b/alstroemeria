param(
    [Alias("t")]
    [int]$ElapsedTime = 0
)

# COM Surrogateプロセス名
$processName = "dllhost"

# プロセス一覧を取得（COM SurrogateのプロセスIDで特定）
$processes = Get-CimInstance Win32_Process | Where-Object {
    $_.Name -eq "dllhost.exe" -and $_.CommandLine -like "*{AB8902B4-09CA-4BB6-B78D-A8F59079A8D5}*"
}

if ($processes.Count -eq 0) {
    Write-Host "COM Surrogateプロセスが見つかりません。"
} else {
    $killedCount = 0

    foreach ($process in $processes) {
        $shouldKill = $false
        $processId = $process.ProcessId
        
        # プロセス開始時刻を取得
        $startTime = $process.CreationDate
        
        if ($ElapsedTime -gt 0) {
            # 経過時間をチェック
            $elapsed = (Get-Date) - $startTime
            if ($elapsed.TotalSeconds -gt $ElapsedTime) {
                $shouldKill = $true
                Write-Host "プロセスID ${processId}: 経過時間 $([math]::Round($elapsed.TotalSeconds))秒 (閾値: ${ElapsedTime}秒超過) - Kill対象"
            } else {
                Write-Host "プロセスID ${processId}: 経過時間 $([math]::Round($elapsed.TotalSeconds))秒 - Skip"
            }
        } else {
            # 時間指定なしの場合は全てkill
            $shouldKill = $true
            $elapsed = (Get-Date) - $startTime
            Write-Host "プロセスID ${processId}: 経過時間 $([math]::Round($elapsed.TotalSeconds))秒 - Kill対象"
        }
        
        if ($shouldKill) {
            try {
                Stop-Process -Id $processId -Force
                Write-Host "プロセスID ${processId} を終了しました。"
                $killedCount++
            } catch {
                Write-Host "プロセスID ${processId} の終了に失敗: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    # 結果表示
    if ($killedCount -gt 0) {
        Write-Host "${killedCount}件のCOM Surrogateを停止しました。" -ForegroundColor Green
    } else {
        Write-Host "停止対象のCOM Surrogateはありませんでした。" -ForegroundColor Yellow
    }
}

# 結果を確認できるようにpause
Write-Host "何かキーを押して終了してください..."
Read-Host
