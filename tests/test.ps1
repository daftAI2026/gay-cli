# [INPUT]: 依赖 Windows PowerShell 与待测的 ../bin/gay.cmd、../bin/_gay.ps1、../bin/gay.mjs、../install.ps1
# [OUTPUT]: 在 Windows 环境使用隔离 mock agy.cmd 端到端校验参数重写、空格/等号保留、退出码与安装器
# [POS]: tests/ 的 Windows 端到端测试入口，与 test.sh 形成全平台 CI 验证闭环
# [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
$TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("gay-cli-test-" + [guid]::NewGuid().ToString("N"))
$MockBin = Join-Path $TmpDir "mock-bin"
New-Item -ItemType Directory -Force -Path $MockBin | Out-Null

try {
    # 构造 mock agy.cmd（使用 PowerShell 精确打印每个参数，规避 cmd 回显差异）
    $mockPs1 = Join-Path $MockBin "_mock_agy.ps1"
    Set-Content -Path $mockPs1 -Value @'
if ($env:MOCK_AGY_EXIT -and $env:MOCK_AGY_EXIT -ne "0") {
    exit ([int]$env:MOCK_AGY_EXIT)
}
Write-Output ("ARGC=" + $args.Count)
foreach ($a in $args) {
    Write-Output ("ARG=[" + $a + "]")
}
'@
    Set-Content -Path (Join-Path $MockBin "agy.cmd") -Value @"
@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$mockPs1" %*
exit /b %ERRORLEVEL%
"@

    $origPath = $env:PATH
    $env:PATH = "$MockBin;$origPath"

    function Assert-Eq($Name, $Expected, $Actual) {
        if ($Expected -ne $Actual) {
            throw "[FAIL] $Name`nExpected:`n$Expected`nActual:`n$Actual"
        }
        Write-Host "  [PASS] $Name"
    }

    function Run-Suite($Label, $CmdBlock) {
        Write-Host "=== Testing $Label ==="
        $out = (& $CmdBlock @()) -join "`n"
        Assert-Eq "${Label}: no args" "ARGC=0" $out

        $out = (& $CmdBlock @("--yolo")) -join "`n"
        Assert-Eq "${Label}: --yolo rewrite" "ARGC=1`nARG=[--dangerously-skip-permissions]" $out

        $out = (& $CmdBlock @("-c", "--yolo", "--effort=high")) -join "`n"
        Assert-Eq "${Label}: mixed & equals" "ARGC=3`nARG=[-c]`nARG=[--dangerously-skip-permissions]`nARG=[--effort=high]" $out

        $out = (& $CmdBlock @("--yolo", "-p", "hello --yolo world")) -join "`n"
        Assert-Eq "${Label}: spaces preserved" "ARGC=3`nARG=[--dangerously-skip-permissions]`nARG=[-p]`nARG=[hello --yolo world]" $out

        $out = (& $CmdBlock @("--yolo", "--", "--yolo")) -join "`n"
        Assert-Eq "${Label}: stop after --" "ARGC=3`nARG=[--dangerously-skip-permissions]`nARG=[--]`nARG=[--yolo]" $out

        $env:MOCK_AGY_EXIT = "42"
        & $CmdBlock @("--yolo") | Out-Null
        $code = $LASTEXITCODE
        Remove-Item Env:\MOCK_AGY_EXIT -ErrorAction SilentlyContinue
        Assert-Eq "${Label}: exit code passthrough" "42" "$code"

        $out = (& $CmdBlock @("--help")) -join "`n"
        $expectedHelp = "gay-cli (agy trampoline):`n  --yolo                          Alias for --dangerously-skip-permissions`n`nARGC=1`nARG=[--help]"
        Assert-Eq "${Label}: top-level --help header" $expectedHelp $out

        $out = (& $CmdBlock @("mcp", "--help")) -join "`n"
        Assert-Eq "${Label}: subcommand --help untouched" "ARGC=2`nARG=[mcp]`nARG=[--help]" $out
    }

    $gayCmd = Join-Path $RootDir "bin\gay.cmd"
    $gayMjs = Join-Path $RootDir "bin\gay.mjs"

    Run-Suite "bin/gay.cmd + _gay.ps1" { param($a) & $gayCmd @a }
    Run-Suite "bin/gay.mjs (Node)" { param($a) & node $gayMjs @a }

    # 校验缺失 agy 时返回 127（PowerShell 5.1 下原生命令写 stderr 会触发 ErrorActionPreference=Stop）
    $env:PATH = "$env:SystemRoot\System32;$env:SystemRoot\System32\WindowsPowerShell\v1.0"
    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & $gayCmd 2>$null
    $missingCode = $LASTEXITCODE
    $ErrorActionPreference = $prevPref
    Assert-Eq "bin/gay.cmd: missing agy exit 127" "127" "$missingCode"

    # 恢复包含 mock agy 的 PATH 并测试 install.ps1（仅检查文件复制）
    $env:PATH = "$MockBin;$origPath"
    $installTarget = Join-Path $TmpDir "installed-bin"
    $env:GAY_INSTALL_DIR = $installTarget
    $env:GAY_SKIP_PATH_UPDATE = "1"
    & (Join-Path $RootDir "install.ps1") | Out-Null
    $out = (& (Join-Path $installTarget "gay.cmd") --yolo) -join "`n"
    Assert-Eq "install.ps1: installed binary works" "ARGC=1`nARG=[--dangerously-skip-permissions]" $out

    Write-Host "`nAll Windows tests passed."
} finally {
    Remove-Item Env:\GAY_INSTALL_DIR -ErrorAction SilentlyContinue
    Remove-Item Env:\GAY_SKIP_PATH_UPDATE -ErrorAction SilentlyContinue
    Remove-Item Env:\MOCK_AGY_EXIT -ErrorAction SilentlyContinue
    if ($origPath) { $env:PATH = $origPath }
    Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
}
