<p align="right"><b>macOS</b> · <b>Linux</b> · <b>Windows</b></p>

<div align="center">
  <h1>gay-cli</h1>
  <p><b>零常驻开销的 <code>agy</code> CLI 跨平台跳转跳板。输入 <code>gay</code> 直达 <code>agy</code>，输入 <code>gay --yolo</code> 等价 <code>agy --dangerously-skip-permissions</code>。</b></p>
  <p><a href="README.md">English</a> · <b>中文</b></p>
  <a href="https://github.com/daftAI2026/gay-cli/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/daftAI2026/gay-cli/ci.yml?branch=main&style=flat-square&label=CI" alt="CI"></a>
  <a href="https://github.com/daftAI2026/gay-cli/stargazers"><img src="https://img.shields.io/github/stars/daftAI2026/gay-cli?style=flat-square" alt="Stars"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square" alt="License"></a>
  <img src="https://img.shields.io/badge/dependencies-0-brightgreen.svg?style=flat-square" alt="Zero Dependencies">
</div>

> **前置要求**：`gay` 依赖宿主环境已安装的 `agy` CLI。请先安装 `agy` 并确保其位于系统 `PATH` 中。

## 核心特性

- **Unix 零内存常驻**：纯 POSIX `#!/bin/sh` 配合 `exec agy "$@"` 原地替换进程映像（~1ms 启动、**0 字节**常驻内存、TTY / TUI / 信号与退出码 100% 原生透传）。
- **全平台原生覆盖**：原生支持 macOS、Linux 与 Windows（PowerShell & CMD），同时兼容免 npm 源的 GitHub 直装。
- **零第三方依赖**：全部为可审计纯文本脚本，免编译、无未签名二进制，杜绝 macOS Gatekeeper 与 Windows Defender 误报。
- **无损透明透传**：仅在 `--` 之前重写 `--yolo`，其余所有参数、子命令、空格引号与退出码原封不动交给 `agy`。

## 快速开始

**macOS / Linux（推荐：0 字节常驻内存）**

```sh
curl -fsSL https://raw.githubusercontent.com/daftAI2026/gay-cli/main/install.sh | sh
```

**Windows（PowerShell）**

```powershell
irm https://raw.githubusercontent.com/daftAI2026/gay-cli/main/install.ps1 | iex
```

**通过 GitHub 使用 npm 全平台安装（无需 npm 账号）**

```sh
npm install -g github:daftAI2026/gay-cli
```

**交给 AI Agent 自动安装**

直接对你的 Agent（Antigravity、Claude Code、Codex、Cursor 等）说：

> 请阅读 https://raw.githubusercontent.com/daftAI2026/gay-cli/main/llms.txt 帮我安装 gay-cli

**使用示例**

```sh
gay                             # 启动 agy
gay --yolo                      # 等价 agy --dangerously-skip-permissions
gay --yolo -c                   # yolo 模式继续上次会话
gay --yolo -p "帮我重构这段代码" # 含空格参数与子命令原样透传
gay -- --yolo                   # -- 之后停止参数重写
gay --help                      # 直接透传 agy 原生帮助
```

<details>
<summary><strong>自定义路径与卸载方式</strong></summary>

macOS / Linux 指定自定义安装目录：

```sh
curl -fsSL https://raw.githubusercontent.com/daftAI2026/gay-cli/main/install.sh | sh -s -- --prefix "$HOME/.local/bin"
```

卸载（macOS / Linux）：

```sh
rm -f "${GAY_INSTALL_DIR:-$HOME/.local/bin}/gay"
```

卸载（Windows PowerShell）：

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\gay"
```

卸载（npm 安装方式）：

```sh
npm uninstall -g gay-cli
```

</details>

## 第一性原理架构

| 平台 / 渠道 | 入口文件 | 核心机制 | 常驻内存 |
| :--- | :--- | :--- | :--- |
| macOS / Linux / WSL | `bin/gay` | POSIX `/bin/sh` + `exec agy "$@"` 进程替换 | **0 B** |
| Windows (CMD / PowerShell) | `bin/gay.cmd` + `bin/_gay.ps1` | 系统签名 PowerShell（绕过默认 ExecutionPolicy） | 原生控制台 |
| GitHub `npm i -g` | `bin/gay.mjs` | 零依赖 Node ESM（精确引号转义 + `SIGINT` 保护） | 跨平台垫片 |

## 本地开发与验证

```sh
make test      # 运行 Unix 端到端测试套件
make check     # 静态语法检查（sh -n 与 node --check）
make install   # 本地安装至 ~/.local/bin/gay
```

## 开源协议

[MIT](LICENSE)
