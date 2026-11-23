#!/usr/bin/env node
/**
 * [INPUT]: 依赖 node:child_process 与 node:os，以及宿主 PATH 中的 agy 可执行文件
 * [OUTPUT]: 对外提供跨平台 npm bin 入口，支持 npm i -g github:daftAI2026/gay-cli
 * [POS]: bin/ 的跨平台 Node 适配层，作为无需 npm 账号的 GitHub 直接安装通道，Unix 优先推荐使用 bin/gay
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import { spawn, spawnSync } from "node:child_process";
import os from "node:os";

// ---------- 1. 参数重写 ----------
function rewriteArgs(argv) {
  const result = [];
  let passthrough = false;

  for (const arg of argv) {
    if (!passthrough && arg === "--") {
      passthrough = true;
      result.push(arg);
    } else if (!passthrough && arg === "--yolo") {
      result.push("--dangerously-skip-permissions");
    } else {
      result.push(arg);
    }
  }
  return result;
}

// ---------- 2. 定位 agy 可执行文件 ----------
function resolveAgy() {
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

function exitMissing() {
  process.stderr.write(
    "gay: 未检测到 agy CLI，请先安装 agy 并确保其位于 PATH 中。\n",
  );
  process.exit(127);
}

// ---------- 3. 透传启动与信号转发 ----------
const agyPath = resolveAgy();
if (!agyPath) {
  exitMissing();
}

const forwarded = rewriteArgs(process.argv.slice(2));
const isWinBatch =
  process.platform === "win32" && /\.(cmd|bat)$/i.test(agyPath);

const child = spawn(agyPath, forwarded, {
  stdio: "inherit",
  shell: isWinBatch,
});

// 前台进程组收到 SIGINT 时由 agy 自行处理，避免父进程抢先退出破坏 TUI
process.on("SIGINT", () => {});
process.on("SIGTERM", () => child.kill("SIGTERM"));

child.on("error", (err) => {
  if (err && err.code === "ENOENT") {
    exitMissing();
  }
  process.stderr.write(`gay: 启动 agy 失败: ${err.message}\n`);
  process.exit(1);
});

child.on("exit", (code, signal) => {
  if (signal) {
    const sigNum = os.constants.signals[signal];
    process.exit(typeof sigNum === "number" ? 128 + sigNum : 1);
  }
  process.exit(code ?? 0);
});
