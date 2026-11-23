# bin/

> L2 | 父级: ../CLAUDE.md

核心职责：承载各操作系统的 `gay -> agy` 参数重写、顶层 `-h`/`--help` 头部追加、交互式 TTY 触发行自动抹除与进程移交入口。除 `--yolo` 替换为 `--dangerously-skip-permissions`（遇 `--` 停止重写）外，全量透明透传其余参数与退出码；顶层 `-h`/`--help` 输出带分隔线的 `gay-cli` 映射头部后照常透传 `agy` 帮助；非打印/非帮助/非子命令的交互式启动前自动清理触发行（可用 `GAY_NO_CLEAR=1` 关闭）；依赖缺失时写 `stderr` 并返回 `127`。

> 成员清单
> gay: Unix 原生核心跳板，POSIX `/bin/sh` 原地位置参数重写 + `exec agy "$@"` 进程替换，0 字节常驻内存，覆盖 macOS / Linux / WSL / Git Bash
> gay.cmd: Windows 统一命令入口，调用同目录 `_gay.ps1` 并绕过默认 ExecutionPolicy，以 `%*` 原始透传参数规避 batch 拆分 `=` 缺陷
> _gay.ps1: Windows 原生参数重写与执行体，下划线前缀避免被 PowerShell 优先命中受阻，通过 `Get-Command -CommandType Application` 精准定位 `agy`
> gay.mjs: 由 `../src/gay.mts` 经 `tsc` 编译生成的零依赖 Node.js ESM 跨平台产物（请勿手改，改源码后执行 `make build`），服务于 `npm i -g github:daftAI2026/gay-cli`

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
