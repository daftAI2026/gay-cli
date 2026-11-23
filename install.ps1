# [INPUT]: 依赖 Windows PowerShell 5.1+/7+ 与宿主 PATH 中的 agy CLI
# [OUTPUT]: 将 bin/gay.cmd 与 bin/_gay.ps1 安装至 %LOCALAPPDATA%\gay\bin 并幂等写入用户 PATH
# [POS]: 根目录 Windows 一键安装器，支持本地仓库与 GitHub Raw (irm | iex) 远程安装
# [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
$ErrorActionPreference = "Stop"

$RepoRawUrl = if ($env:GAY_REPO_RAW_URL) { $env:GAY_REPO_RAW_URL } else { "https://raw.githubusercontent.com/daftAI2026/gay-cli/main" }
$InstallDir = if ($env:GAY_INSTALL_DIR) { $env:GAY_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA "gay\bin" }

# ---------- 1. 前置依赖检查 ----------
if ($env:GAY_SKIP_AGY_CHECK -ne "1") {
    $agy = Get-Command agy -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $agy) {
        [Console]::Error.WriteLine("install: 未检测到 agy CLI，请先安装 agy 后再安装 gay。")
        exit 127
    }
}

# ---------- 2. 安装 gay.cmd 与 _gay.ps1 ----------
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

$LocalBin = if ($PSScriptRoot) { Join-Path $PSScriptRoot "bin" } else { "" }
foreach ($file in @("gay.cmd", "_gay.ps1")) {
    $dest = Join-Path $InstallDir $file
    $localSrc = if ($LocalBin) { Join-Path $LocalBin $file } else { "" }
    if ($localSrc -and (Test-Path $localSrc)) {
        Copy-Item -Force $localSrc $dest
    } else {
        Invoke-WebRequest -UseBasicParsing -Uri "$RepoRawUrl/bin/$file" -OutFile $dest
    }
}

# ---------- 3. 幂等写入用户 PATH ----------
if ($env:GAY_SKIP_PATH_UPDATE -eq "1") {
    Write-Host "gay 已安装至: $InstallDir"
    exit 0
}

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$entries = @()
if ($userPath) {
    $entries = $userPath -split ";" | Where-Object { $_ -ne "" }
}

if ($entries -notcontains $InstallDir) {
    $newPath = ($entries + $InstallDir) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "已将 $InstallDir 写入用户 PATH，请重开终端后直接运行 gay。"
} else {
    Write-Host "gay 已安装至: $InstallDir"
}
