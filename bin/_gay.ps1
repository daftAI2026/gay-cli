# [INPUT]: 依赖宿主 PATH 中的 agy 可执行文件，由同目录 gay.cmd 原始透传参数调用
# [OUTPUT]: 完成 Windows 平台参数重写（--yolo -> --dangerously-skip-permissions）、交互式控制台抹除触发行并原样返回 agy 退出码
# [POS]: bin/ 的 Windows 原生执行体，命名以下划线开头避免在 PowerShell 中被 ExecutionPolicy 拦截
# [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md

# ---------- 1. 前置依赖检查 ----------
$agy = Get-Command agy -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $agy) {
    [Console]::Error.WriteLine("gay: 未检测到 agy CLI，请先安装 agy 并确保其位于 PATH 中。")
    exit 127
}

# ---------- 2. 参数重写 + 交互模式判断 ----------
$forwarded = New-Object System.Collections.Generic.List[string]
$passthrough = $false
$shouldClear = $true

if ($args.Count -gt 0 -and -not $args[0].StartsWith("-")) {
    $shouldClear = $false
}

foreach ($arg in $args) {
    if (-not $passthrough) {
        if ($arg -eq "--") {
            $passthrough = $true
            $forwarded.Add($arg)
        } elseif ($arg -eq "--yolo") {
            $forwarded.Add("--dangerously-skip-permissions")
        } else {
            if ($arg -in @("-h", "--help", "-p", "--print", "--prompt") -or $arg.StartsWith("--prompt=")) {
                $shouldClear = $false
            }
            $forwarded.Add($arg)
        }
    } else {
        $forwarded.Add($arg)
    }
}

# ---------- 3. 顶层帮助头部 / 交互式控制台抹除触发行 ----------
if ($args.Count -eq 1 -and ($args[0] -eq "-h" -or $args[0] -eq "--help")) {
    [Console]::Out.Write("gay-cli (agy trampoline):`n  --yolo                          Alias for --dangerously-skip-permissions`n--------------------------------------------------------------------------`n`n")
} elseif ($shouldClear -and (-not [Console]::IsOutputRedirected) -and ($env:GAY_NO_CLEAR -ne "1")) {
    $esc = [char]27
    [Console]::Write("${esc}[1A${esc}[2K`r")
}

# ---------- 4. 透传执行并保留退出码 ----------
& $agy.Source @forwarded
if ($null -eq $LASTEXITCODE) {
    exit 0
}
exit $LASTEXITCODE
