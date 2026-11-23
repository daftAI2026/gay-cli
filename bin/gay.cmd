@echo off
rem [INPUT]: 依赖 Windows PowerShell 与同目录 _gay.ps1 脚本
rem [OUTPUT]: 对外提供 Windows CMD 与 PowerShell 统一的 gay 命令入口
rem [POS]: bin/ 的 Windows 入口垫片，绕过默认 ExecutionPolicy 并以 %* 原始透传参数（避免 batch 拆分 = 号）
rem [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0_gay.ps1" %*
exit /b %ERRORLEVEL%
