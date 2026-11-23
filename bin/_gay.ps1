# [INPUT]: 依赖宿主 PATH 中的 agy 可执行文件，由同目录 gay.cmd 原始透传参数调用
# [OUTPUT]: 完成 Windows 平台参数重写（--yolo -> --dangerously-skip-permissions）并原样返回 agy 退出码
# [POS]: bin/ 的 Windows 原生执行体，命名以下划线开头避免在 PowerShell 中被 ExecutionPolicy 拦截
# [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md

# ---------- 1. 前置依赖检查 ----------
$agy = Get-Command agy -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $agy) {
    [Console]::Error.WriteLine("gay: 未检测到 agy CLI，请先安装 agy 并确保其位于 PATH 中。")
    exit 127
}

# ---------- 2. 参数重写 ----------
$forwarded = New-Object System.Collections.Generic.List[string]
$passthrough = $false

foreach ($arg in $args) {
    if (-not $passthrough) {
        if ($arg -eq "--") {
            $passthrough = $true
            $forwarded.Add($arg)
        } elseif ($arg -eq "--yolo") {
            $forwarded.Add("--dangerously-skip-permissions")
        } else {
            $forwarded.Add($arg)
        }
    } else {
        $forwarded.Add($arg)
    }
}

# ---------- 3. 透传执行并保留退出码 ----------
& $agy.Source @forwarded
if ($null -eq $LASTEXITCODE) {
    exit 0
}
exit $LASTEXITCODE
