param (
    [switch]$d,
    [string]$u,
    [int]$s,
    [switch]$h
)

function Show-Help {
    Write-Host "AppDataフォルダのサイズ分析を行います。"
    Write-Host ""
    Write-Host "usage)"
    Write-Host "    check-appdata.ps1 [-d] [-u USER] [-s SIZE]"
    Write-Host ""
    Write-Host "options)"
    Write-Host "    -d     デフォルト設定を使用 (現在のユーザー、最小サイズ 500MB)"
    Write-Host "    -u     分析対象のユーザー名を指定"
    Write-Host "    -s     表示する最小サイズ (MB) を指定"
    Write-Host ""
    exit
}

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Get-CurrentUsername {
    return [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
}

function Get-AppDataPath {
    param (
        [string]$Username
    )
    if ([string]::IsNullOrEmpty($Username) -or $Username -eq (Get-CurrentUsername)) {
        return Split-Path $env:APPDATA -Parent
    }
    else {
        $userProfile = (Get-CimInstance -ClassName Win32_UserProfile | Where-Object { $_.LocalPath.split('\')[-1] -eq $Username }).LocalPath
        if ($userProfile) {
            return Join-Path $userProfile "AppData"
        }
        else {
            Write-Error "指定されたユーザー '$Username' が見つかりません。"
            exit
        }
    }
}

function Get-FolderInfo {
    param (
        [string]$Path
    )
    $item = Get-Item -Path $Path -Force
    if ($item.LinkType -eq "SymbolicLink") {
        $targetPath = $item.Target
        return [PSCustomObject]@{
            Name = $item.Name
            SizeMB = 0.00
            FullPath = "$($item.Name) -> $targetPath"
        }
    } else {
        $size = (Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum
        $sizeInMB = [math]::Round($size / 1MB, 2)
        return [PSCustomObject]@{
            Name = $item.Name
            SizeMB = $sizeInMB
            FullPath = $item.FullName
        }
    }
}

# ヘルプ表示または不正なパラメータ指定時の処理
if ($h -or (-not $d -and -not $u -and -not $s)) {
    Show-Help
}

# デフォルト値の設定
if ($d -or (-not $u -and -not $s)) {
    $u = Get-CurrentUsername
    $s = 500
}

# 管理者権限チェック
if ($u -and ($u -ne (Get-CurrentUsername))) {
    if (-not (Test-Admin)) {
        Write-Error "他のユーザーのAppDataにアクセスするには管理者権限が必要です。スクリプトを管理者として実行してください。"
        exit
    }
}

$appDataPath = Get-AppDataPath -Username $u
$appDataFolders = @('Local', 'LocalLow', 'Roaming')

foreach ($folder in $appDataFolders) {
    Write-Host "`n$folder フォルダの内容:"
    Get-ChildItem -Path "$appDataPath\$folder" -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
        Get-FolderInfo -Path $_.FullName
    } | Where-Object { $_.SizeMB -ge $s } | 
    Sort-Object -Property SizeMB -Descending | 
    Format-Table -AutoSize @{
        Label = "Name"
        Expression = { $_.Name }
    }, @{
        Label = "SizeMB"
        Expression = { "{0:F2}" -f $_.SizeMB }
        Align = 'Right'
    }, @{
        Label = "FullPath"
        Expression = { $_.FullPath }
    }
}
