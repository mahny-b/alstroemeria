param (
    [string]$u,
    [int]$s = 500
)

function Show-Help {
    Write-Host ""
    Write-Host "AppData Size Analysis Script"
    Write-Host "Usage: .\script_name.ps1 [-u <username>] [-s <size>]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -u    Optional. Specifies the user whose AppData to analyze. If not provided, uses the current user."
    Write-Host "  -s    Optional. Specifies the minimum folder size in MB to display. Default is 500 MB."
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\script_name.ps1"
    Write-Host "  .\script_name.ps1 -u JohnDoe"
    Write-Host "  .\script_name.ps1 -s 1000"
    Write-Host "  .\script_name.ps1 -u JohnDoe -s 1000"
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
    if ([string]::IsNullOrEmpty($Username) -or $Username -eq $currentUsername) {
        # 現在のユーザーの AppData パスを取得
        return Split-Path $env:APPDATA -Parent
    }
    else {
        # 指定されたユーザーの AppData パスを取得
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
            SizeMB = 0
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

# メイン処理開始

# 引数チェックとヘルプ表示
if ($args.Count -gt 0 -and (-not $u -and -not $s)) {
    Show-Help
}

$currentUsername = Get-CurrentUsername

# 管理者権限チェック
if ($u -and ($u -ne $currentUsername)) {
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

