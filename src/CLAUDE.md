# src/

> L2 | 父级: ../CLAUDE.md

核心职责：存放跨平台 npm 垫片的严格 TypeScript 源码真源（零运行时依赖）。修改后运行 `npm run build` 编译同步至 `bin/gay.mjs`，CI 自动校验编译产物一致性。

> 成员清单
> gay.mts: TypeScript 源码入口，实现参数重写（`--yolo` -> `--dangerously-skip-permissions`）、跨平台 `agy` 路径解析、Windows `.cmd` 精确引号转义及 `SIGINT`/`SIGTERM` 透传，编译输出至 `../bin/gay.mjs`

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
