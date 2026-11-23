# gay-cli

极简、零常驻开销的 [`agy`](https://github.com/daftAI2026/gay-cli) CLI 跨平台跳转别名工具。

## 命令映射

| 输入命令 | 实际执行 |
| :--- | :--- |
| `gay` | `agy` |
| `gay --yolo` | `agy --dangerously-skip-permissions` |
| `gay [任意参数与子命令]` | 全量透传至 `agy`（`--` 之后停止重写 `--yolo`） |

> **前置要求**：使用前需已安装 `agy` CLI 并确保 `agy` 位于系统 `PATH` 中。

---

## 安装方式（全平台，无需 npm 源）

### macOS / Linux（推荐：0 字节常驻内存）

```sh
curl -fsSL https://raw.githubusercontent.com/daftAI2026/gay-cli/main/install.sh | sh
```

安装至 `~/.local/bin/gay`（与 `agy` 同目录）。可通过 `GAY_INSTALL_DIR` 自定义目标目录。

### Windows（PowerShell）

```powershell
irm https://raw.githubusercontent.com/daftAI2026/gay-cli/main/install.ps1 | iex
```

安装至 `%LOCALAPPDATA%\gay\bin` 并自动写入用户 `PATH`，同时兼容 PowerShell 与 CMD，自动绕过默认 `ExecutionPolicy` 限制。

### 通过 GitHub 使用 npm 全局安装（macOS / Linux / Windows 通用）

```sh
npm install -g github:daftAI2026/gay-cli
```

---

## 架构设计（第一性原理）

`gay` 不是一个常驻应用，而是一个**参数重写 + 进程移交跳板**：

- **macOS / Linux (`bin/gay`)**：纯 POSIX `/bin/sh` 实现，零依赖、零编译，通过 `exec agy "$@"` 原地替换当前进程映像。启动耗时 ~1ms，进入 `agy` 后 `gay` 进程彻底消失——**0 字节常驻内存**，TTY / TUI / `SIGINT` / `SIGWINCH` 与退出码 100% 原生无损。
- **Windows (`bin/gay.cmd` + `bin/_gay.ps1`)**：利用系统自带签名宿主（零 Defender / SmartScreen 误报），`gay.cmd` 统一承接 CMD 与 PowerShell 入口并以 `%*` 原始透传参数，`_gay.ps1` 完成精准参数重写与退出码传递。
- **GitHub npm (`bin/gay.mjs`)**：零第三方依赖 ESM 垫片，兼容三端 `npm i -g github:daftAI2026/gay-cli`，正确处理前台进程组 `SIGINT` 避免中断 `agy` TUI。

---

## 本地开发与验证

```sh
sh ./tests/test.sh
```

## License

MIT
