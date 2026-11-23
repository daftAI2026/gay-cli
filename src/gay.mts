#!/usr/bin/env node
/**
 * [INPUT]: 依赖 node:child_process 与 node:os，以及宿主 PATH 中的 agy 可执行文件
 * [OUTPUT]: 编译输出至 bin/gay.mjs，作为 npm i -g github:daftAI2026/gay-cli 的跨平台可执行入口（含交互式 TTY 触发行清理）
 * [POS]: src/ 的唯一 TypeScript 源码真源（Single Source of Truth），经 tsc 编译生成 bin/gay.mjs
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import { spawn, spawnSync, type ChildProcess } from "node:child_process";
import os from "node:os";

// ---------- 1. 参数重写与交互模式判断 ----------
export interface RewriteResult {
  readonly args: string[];
  readonly shouldClear: boolean;
}

export function rewriteArgs(argv: readonly string[]): RewriteResult {
  const result: string[] = [];
  let passthrough = false;
  let shouldClear = argv.length === 0 || argv[0].startsWith("-");

  for (const arg of argv) {
    if (!passthrough && arg === "--") {
      passthrough = true;
      result.push(arg);
    } else if (!passthrough && arg === "--yolo") {
      result.push("--dangerously-skip-permissions");
    } else {
      if (
        !passthrough &&
        (arg === "-h" ||
          arg === "--help" ||
          arg === "-p" ||
          arg === "--print" ||
          arg === "--prompt" ||
          arg.startsWith("--prompt="))
      ) {
        shouldClear = false;
      }
      result.push(arg);
    }
  }
  return { args: result, shouldClear };
}

// ---------- 2. 定位 agy 可执行文件 ----------
function resolveAgy(): string | null {
  const isWin = process.platform === "win32";
  const probe = spawnSync(isWin ? "where" : "which", ["agy"], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "ignore"],
  });

  if (probe.status !== 0 || !probe.stdout.trim()) {
    return null;
  }

  const candidates = probe.stdout
    .trim()
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);

  if (isWin) {
    // Windows PATH 中可能同时存在无扩展名 sh 脚本与 .exe/.cmd，优先匹配可执行扩展名
    const executable = candidates.find((p) => /\.(exe|com|cmd|bat)$/i.test(p));
    return executable ?? candidates[0] ?? null;
  }
  return candidates[0] ?? null;
}

function exitMissing(): never {
  process.stderr.write(
    "gay: 未检测到 agy CLI，请先安装 agy 并确保其位于 PATH 中。\n",
  );
  process.exit(127);
}

// ---------- 3. 透传启动与信号转发 ----------
function quoteWinCmdArg(arg: string): string {
  if (arg === "") return '""';
  if (!/[\s"&|<>^()]/.test(arg)) return arg;
  return `"${arg.replace(/"/g, '\\"')}"`;
}

function spawnAgy(agyPath: string, forwarded: readonly string[]): ChildProcess {
  const isWinBatch =
    process.platform === "win32" && /\.(cmd|bat)$/i.test(agyPath);

  if (isWinBatch) {
    const cmdLine = [
      quoteWinCmdArg(agyPath),
      ...forwarded.map(quoteWinCmdArg),
    ].join(" ");
    return spawn(
      process.env.ComSpec || "cmd.exe",
      ["/d", "/s", "/c", `"${cmdLine}"`],
      { stdio: "inherit", windowsVerbatimArguments: true },
    );
  }
  return spawn(agyPath, [...forwarded], { stdio: "inherit" });
}

function main(): void {
  const agyPath = resolveAgy();
  if (!agyPath) {
    exitMissing();
  }

  const rawArgs = process.argv.slice(2);
  const { args: forwarded, shouldClear } = rewriteArgs(rawArgs);

  // 顶层 -h/--help 追加 3 行 gay 映射，否则交互式 TTY 启动前抹除上一行触发命令
  if (rawArgs.length === 1 && (rawArgs[0] === "-h" || rawArgs[0] === "--help")) {
    process.stdout.write(
      "gay-cli (agy trampoline):\n  --yolo                          Alias for --dangerously-skip-permissions\n\n",
    );
  } else if (
    shouldClear &&
    process.stdout.isTTY &&
    process.env.GAY_NO_CLEAR !== "1"
  ) {
    process.stdout.write("\x1b[1A\x1b[2K\r");
  }

  const child = spawnAgy(agyPath, forwarded);

  // 前台进程组收到 SIGINT 时由 agy 自行处理，避免父进程抢先退出破坏 TUI
  process.on("SIGINT", () => {});
  process.on("SIGTERM", () => child.kill("SIGTERM"));

  child.on("error", (err: NodeJS.ErrnoException) => {
    if (err.code === "ENOENT") {
      exitMissing();
    }
    process.stderr.write(`gay: 启动 agy 失败: ${err.message}\n`);
    process.exit(1);
  });

  child.on("exit", (code: number | null, signal: NodeJS.Signals | null) => {
    if (signal) {
      const signals = os.constants.signals as Record<string, number>;
      const sigNum = signals[signal];
      process.exit(typeof sigNum === "number" ? 128 + sigNum : 1);
    }
    process.exit(code ?? 0);
  });
}

main();
