# gay-cli Agent Guide

Shared engineering contract for AI coding agents working in this repository (Antigravity, Claude Code, Codex, Cursor, etc.). For the fractal directory & file map, also read `CLAUDE.md`, `bin/CLAUDE.md`, and `tests/CLAUDE.md`.

## Product Scope

`gay-cli` is a minimal, zero-overhead argument-rewriting trampoline for `agy`:

- `gay` -> `agy`
- `gay --yolo` -> `agy --dangerously-skip-permissions`
- Everything else passes through verbatim (stop rewriting after `--`).

### What `gay-cli` Should Do

- Stay zero-runtime-dependency across all platforms: POSIX `sh` (`exec`) on Unix, native `.cmd` + `_gay.ps1` on Windows, and strict TypeScript (`src/gay.mts`) compiled via `tsc` to zero-dep Node ESM (`bin/gay.mjs`) for GitHub npm installs.
- Always edit `src/gay.mts` (never hand-edit `bin/gay.mjs`), then run `make build` so the pre-compiled `bin/gay.mjs` stays in sync for instant `npm i -g github:daftAI2026/gay-cli` installs.
- Guarantee 0-byte resident overhead on macOS/Linux by always terminating the wrapper via `exec agy "$@"`.
- Fail fast with a clear `stderr` message and exit code `127` when `agy` is absent from `PATH`.
- Keep all platform adapters behaviorally identical and verified in CI (`ubuntu-latest`, `macos-latest`, `windows-latest`).

### What `gay-cli` Should Not Do

- Do not parse or duplicate `agy`'s own flags or `--help` output; stay decoupled from `agy` upgrades.
- Do not add third-party npm packages, build bundlers, background daemons, telemetry, or interactive prompts.
- Do not break POSIX `/bin/sh` compatibility in `bin/gay` or `install.sh` (no bashisms, no arrays).

## Verification Contract

Before committing any change:

1. Unix: `sh ./tests/test.sh` (covers `sh -n`, `node --check`, `bin/gay`, `bin/gay.mjs`, and `install.sh`).
2. Windows (CI): `.\tests\test.ps1` (covers `bin/gay.cmd`, `bin/_gay.ps1`, `bin/gay.mjs`, and `install.ps1`).
3. Keep `CLAUDE.md` (L1), `bin/CLAUDE.md` / `tests/CLAUDE.md` (L2), and L3 file headers synchronized with code changes.
