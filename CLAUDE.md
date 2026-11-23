# gay-cli - 零常驻开销的 agy CLI 跨平台跳转别名工具

POSIX Shell (`exec`) + Windows PowerShell/CMD + Zero-Dep Node.js (ESM)

<directory>
bin/ - 跨平台可执行入口集合 (Unix POSIX sh、Windows cmd/ps1、npm 跨平台 Node 垫片)
tests/ - 端到端自动化验证套件 (test.sh 覆盖 Unix，test.ps1 覆盖 Windows)
.github/ - GitHub Actions 三端 CI 工作流 (ubuntu / macos / windows)
</directory>

<config>
package.json - GitHub npm 直装清单 (`npm i -g github:daftAI2026/gay-cli`)，零第三方依赖
install.sh - macOS / Linux 一键安装脚本，部署 bin/gay 至 ~/.local/bin/gay
install.ps1 - Windows PowerShell 一键安装脚本，部署 gay.cmd 与 _gay.ps1 并写入用户 PATH
README.md - 安装指南、映射规则与第一性原理架构说明
LICENSE - MIT 开源协议
</config>

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
