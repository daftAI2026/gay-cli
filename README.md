<div align="center">
  <h1>gay-cli</h1>
  <p><b>Zero-overhead cross-platform CLI trampoline for <a href="https://github.com/google-antigravity/antigravity-cli"><code>agy</code></a>.</b></p>
  <p><b>English</b> · <a href="README_CN.md">中文</a></p>
  <a href="https://github.com/daftAI2026/gay-cli/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/daftAI2026/gay-cli/ci.yml?branch=main&style=flat-square&label=CI" alt="CI"></a>
  <a href="https://github.com/daftAI2026/gay-cli/stargazers"><img src="https://img.shields.io/github/stars/daftAI2026/gay-cli?style=flat-square" alt="Stars"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square" alt="License"></a>
  <img src="https://img.shields.io/badge/dependencies-0-brightgreen.svg?style=flat-square" alt="Zero Dependencies">
</div>

> **Prerequisite**: `gay` delegates directly to [`agy`](https://github.com/google-antigravity/antigravity-cli). Install [`antigravity-cli`](https://github.com/google-antigravity/antigravity-cli) first and make sure `agy` is in your `PATH`.

## Features

- **Zero resident overhead on Unix**: Pure POSIX `#!/bin/sh` with `exec agy "$@"`, replacing the wrapper process in-place (~1ms startup, **0 bytes** resident RAM, 100% native TTY/TUI/signals).
- **All platforms out of the box**: Native implementations for macOS, Linux, and Windows (PowerShell & CMD), plus zero-dependency GitHub `npm` install.
- **Zero runtime dependencies**: Auditable scripts with no unsigned binaries and no SmartScreen/Gatekeeper warnings.
- **Transparent passthrough**: Only `--yolo` is rewritten (stopped after `--`); every other flag, subcommand, space, quote, and exit code passes straight through to `agy`.

## Quick Start

**macOS / Linux**

```sh
curl -fsSL https://raw.githubusercontent.com/daftAI2026/gay-cli/main/install.sh | sh
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/daftAI2026/gay-cli/main/install.ps1 | iex
```

**npm (GitHub)**

```sh
npm install -g github:daftAI2026/gay-cli
```

**With an AI agent**

Tell your agent (Antigravity, Claude Code, Codex, Cursor, etc.):

> Install gay-cli for me by reading https://raw.githubusercontent.com/daftAI2026/gay-cli/main/llms.txt

**Run**

```sh
gay                             # Launch agy
gay --yolo                      # agy --dangerously-skip-permissions
gay --yolo -c                   # Continue last session in yolo mode
gay --yolo -p "refactor this"   # All flags & quoted prompts pass through intact
gay -- --yolo                   # Stop rewriting after --
gay --help                      # Full native agy help
```

<details>
<summary><strong>Other install &amp; uninstall options</strong></summary>

Install to a custom directory on macOS / Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/daftAI2026/gay-cli/main/install.sh | sh -s -- --prefix "$HOME/.local/bin"
```

Uninstall on macOS / Linux:

```sh
rm -f "${GAY_INSTALL_DIR:-$HOME/.local/bin}/gay"
```

Uninstall on Windows (PowerShell):

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\gay"
```

Uninstall if installed via npm:

```sh
npm uninstall -g gay-cli
```

</details>

## Architecture

| Platform / Channel | Entrypoint | Mechanism | Resident RAM |
| :--- | :--- | :--- | :--- |
| macOS / Linux / WSL | `bin/gay` | POSIX `/bin/sh` + `exec agy "$@"` | **0 B** |
| Windows (CMD / PowerShell) | `bin/gay.cmd` + `bin/_gay.ps1` | System PowerShell (`-ExecutionPolicy Bypass`) | Native console |
| GitHub `npm i -g` | `bin/gay.mjs` (compiled from `src/gay.mts`) | Strict TypeScript -> zero-dep Node ESM (`SIGINT`-safe) | Cross-platform shim |

## Development

```sh
npm install    # Install TypeScript devDependencies (zero runtime deps)
make build     # Compile src/gay.mts -> bin/gay.mjs
make test      # Run Unix end-to-end test suite (21 assertions)
make check     # Static checks (sh -n, node --check, tsc --noEmit)
make install   # Local install to ~/.local/bin/gay
```

## License

[MIT](LICENSE)
