# tests/

> L2 | 父级: ../CLAUDE.md

核心职责：在不依赖真实 `agy` 会话的前提下，以隔离临时目录中的 mock `agy` 对全套参数重写规则、边界情况、退出码与安装器进行回归验证。

> 成员清单
> test.sh: Unix 端到端测试主脚本，覆盖 `sh -n` / `node --check` 静态检查、`bin/gay` 与 `bin/gay.mjs` 8 组行为断言及 `install.sh` 本地安装验收
> test.ps1: Windows 端到端测试脚本，覆盖 `bin/gay.cmd` + `_gay.ps1`、`bin/gay.mjs` 与 `install.ps1` 的全量行为与退出码断言

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
