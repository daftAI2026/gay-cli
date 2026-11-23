# gay-cli - 零常驻开销的 agy CLI 跨平台跳转别名工具

POSIX Shell (`exec`) + Windows PowerShell/CMD + TypeScript (`tsc` -> Zero-Dep Node ESM)

<directory>
src/ - 跨平台 npm 适配层的严格 TypeScript 源码真源 (`gay.mts`)
bin/ - 跨平台可执行入口集合 (Unix POSIX sh、Windows cmd/ps1、由 src/ 编译的 gay.mjs)
docs/ - 终端演示多媒体资产 (`demo.gif` / `demo.mp4`，已打码并嵌入 README)
tests/ - 端到端自动化验证套件 (test.sh 覆盖 Unix，test.ps1 覆盖 Windows)
.github/ - GitHub Actions 三端 CI 工作流 (TS 编译一致性校验 + ubuntu / macos / windows)
</directory>

<config>
package.json - GitHub npm 直装清单 (`npm i -g github:daftAI2026/gay-cli`)，零运行时依赖，仅开发期依赖 TypeScript
tsconfig.json - 严格 TypeScript 编译配置 (`src/*.mts` -> `bin/*.mjs`, ES2022 + NodeNext)
Makefile - 开发者快捷入口 (`build` / `typecheck` / `test` / `check` / `install` / `uninstall`)
install.sh - macOS / Linux 一键安装脚本，支持 `--prefix` 与 `GAY_INSTALL_DIR`
install.ps1 - Windows PowerShell 一键安装脚本，部署 `gay.cmd` + `_gay.ps1` 并幂等写入用户 PATH
llms.txt - 面向 AI Agent 的标准安装与用法说明（引用 google-antigravity/antigravity-cli）
AGENTS.md - 跨 Agent 共享工程契约与产品边界（做什么 / 不做什么）
README.md - 英文主文档（快速开始、AI Agent 安装、架构表、卸载折叠区）
README_CN.md - 中文镜像文档
.gitattributes - 强制 Unix 脚本 LF、Windows 批处理 CRLF，防止跨平台换行符损坏
.editorconfig - 统一跨编辑器编码与缩进规范
LICENSE - MIT 开源协议
</config>

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
