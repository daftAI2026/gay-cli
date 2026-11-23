#!/bin/sh
# [INPUT]: 依赖 POSIX /bin/sh、curl（远程安装时）及宿主 PATH 中的 agy CLI
# [OUTPUT]: 将 bin/gay 安装至 ${GAY_INSTALL_DIR:-$HOME/.local/bin}/gay 并赋予可执行权限
# [POS]: 根目录 Unix（macOS/Linux）一键安装器，支持本地仓库与 GitHub Raw 远程两种安装模式
# [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
set -eu

REPO_RAW_URL="${GAY_REPO_RAW_URL:-https://raw.githubusercontent.com/daftAI2026/gay-cli/main}"
INSTALL_DIR="${GAY_INSTALL_DIR:-$HOME/.local/bin}"

# 支持 --prefix <dir> 参数覆盖安装目录
while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)
      shift
      [ $# -gt 0 ] || { printf 'install: --prefix 需要指定目录路径。\n' >&2; exit 2; }
      INSTALL_DIR=$1
      ;;
    --prefix=*)
      INSTALL_DIR=${1#--prefix=}
      ;;
  esac
  shift
done

TARGET="$INSTALL_DIR/gay"

# ---------- 1. 前置依赖检查 ----------
if [ "${GAY_SKIP_AGY_CHECK:-0}" != "1" ] && ! command -v agy >/dev/null 2>&1; then
  printf 'install: 未检测到 agy CLI，请先安装 agy 后再安装 gay。\n' >&2
  exit 127
fi

# ---------- 2. 准备目标目录并写入脚本 ----------
mkdir -p "$INSTALL_DIR"

SCRIPT_DIR=""
if [ -n "${0:-}" ] && [ -f "$0" ]; then
  SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
fi

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/bin/gay" ]; then
  cp "$SCRIPT_DIR/bin/gay" "$TARGET"
else
  if ! command -v curl >/dev/null 2>&1; then
    printf 'install: 远程安装需要 curl，请先安装 curl。\n' >&2
    exit 1
  fi
  curl -fsSL "$REPO_RAW_URL/bin/gay" -o "$TARGET"
fi

chmod +x "$TARGET"
printf 'gay 已安装至: %s\n' "$TARGET"

# ---------- 3. PATH 提示 ----------
case ":${PATH:-}:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    printf '提示: 请将以下内容加入你的 shell 配置 (~/.zshrc 或 ~/.bashrc):\n'
    printf '  export PATH="%s:$PATH"\n' "$INSTALL_DIR"
    ;;
esac
