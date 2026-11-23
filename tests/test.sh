#!/bin/sh
# [INPUT]: 依赖 POSIX /bin/sh、node，以及待测的 ../bin/gay、../bin/gay.mjs、../install.sh
# [OUTPUT]: 对所有核心参数重写规则、边界条件、退出码透传与安装脚本执行端到端自动化验证
# [POS]: tests/ 的主测试入口，使用临时目录中的 mock agy 隔离真实环境
# [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

MOCK_BIN="$TMP_DIR/mock-bin"
EMPTY_BIN="$TMP_DIR/empty-bin"
mkdir -p "$MOCK_BIN" "$EMPTY_BIN"

# 构造 mock agy：每行输出一个参数（便于精确验证空格、引号与顺序）
cat > "$MOCK_BIN/agy" << 'EOF'
#!/bin/sh
if [ "${MOCK_AGY_EXIT:-0}" != "0" ]; then
  exit "$MOCK_AGY_EXIT"
fi
printf 'ARGC=%s\n' "$#"
for a in "$@"; do
  printf 'ARG=[%s]\n' "$a"
done
EOF
chmod +x "$MOCK_BIN/agy"

# 为缺失 agy 的场景构造仅含 node 的目录（隔离真实 PATH 中的 agy）
NODE_ONLY_BIN="$TMP_DIR/node-only-bin"
mkdir -p "$NODE_ONLY_BIN"
ln -s "$(command -v node)" "$NODE_ONLY_BIN/node"

PASS=0
FAIL=0

assert_eq() {
  name=$1
  expected=$2
  actual=$3
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf '  [PASS] %s\n' "$name"
  else
    FAIL=$((FAIL + 1))
    printf '  [FAIL] %s\n    expected: %s\n    actual:   %s\n' "$name" "$expected" "$actual" >&2
  fi
}

run_suite_for() {
  label=$1
  runner=$2
  printf '=== Testing %s ===\n' "$label"

  # 1. 无参数透传
  out=$(PATH="$MOCK_BIN:$PATH" "$runner")
  assert_eq "$label: no args" "ARGC=0" "$out"

  # 2. --yolo -> --dangerously-skip-permissions
  out=$(PATH="$MOCK_BIN:$PATH" "$runner" --yolo)
  expected=$(printf 'ARGC=1\nARG=[--dangerously-skip-permissions]')
  assert_eq "$label: --yolo rewrite" "$expected" "$out"

  # 3. 混合参数与顺序保留
  out=$(PATH="$MOCK_BIN:$PATH" "$runner" -c --yolo --model opus)
  expected=$(printf 'ARGC=4\nARG=[-c]\nARG=[--dangerously-skip-permissions]\nARG=[--model]\nARG=[opus]')
  assert_eq "$label: mixed args" "$expected" "$out"

  # 4. 含空格与内部字面量 --yolo 不误改
  out=$(PATH="$MOCK_BIN:$PATH" "$runner" --yolo -p "hello --yolo world")
  expected=$(printf 'ARGC=3\nARG=[--dangerously-skip-permissions]\nARG=[-p]\nARG=[hello --yolo world]')
  assert_eq "$label: spaces preserved" "$expected" "$out"

  # 5. -- 之后停止重写
  out=$(PATH="$MOCK_BIN:$PATH" "$runner" --yolo -- --yolo)
  expected=$(printf 'ARGC=3\nARG=[--dangerously-skip-permissions]\nARG=[--]\nARG=[--yolo]')
  assert_eq "$label: stop after --" "$expected" "$out"

  # 6. 连字符开头参数不被 set 吞掉
  out=$(PATH="$MOCK_BIN:$PATH" "$runner" -n -e --yolo)
  expected=$(printf 'ARGC=3\nARG=[-n]\nARG=[-e]\nARG=[--dangerously-skip-permissions]')
  assert_eq "$label: dash flags safe" "$expected" "$out"

  # 7. 退出码透传
  set +e
  PATH="$MOCK_BIN:$PATH" MOCK_AGY_EXIT=42 "$runner" --yolo >/dev/null 2>&1
  code=$?
  set -e
  assert_eq "$label: exit code passthrough" "42" "$code"

  # 8. 缺少 agy 时返回 127 且输出至 stderr
  set +e
  err=$(PATH="$EMPTY_BIN:$NODE_ONLY_BIN:/usr/bin:/bin" "$runner" 2>&1 >/dev/null)
  code=$?
  set -e
  assert_eq "$label: missing agy exit 127" "127" "$code"
  case "$err" in
    *"agy"*) PASS=$((PASS + 1)); printf '  [PASS] %s\n' "$label: missing agy stderr" ;;
    *) FAIL=$((FAIL + 1)); printf '  [FAIL] %s: %s\n' "$label: missing agy stderr" "$err" >&2 ;;
  esac

  # 9. 顶层 --help 追加 3 行 gay 头部并继续透传，子命令 --help 不追加
  out=$(PATH="$MOCK_BIN:$PATH" "$runner" --help)
  expected=$(printf 'gay-cli (agy trampoline):\n  --yolo                          Alias for --dangerously-skip-permissions\n\nARGC=1\nARG=[--help]')
  assert_eq "$label: top-level --help header" "$expected" "$out"

  out=$(PATH="$MOCK_BIN:$PATH" "$runner" mcp --help)
  expected=$(printf 'ARGC=2\nARG=[mcp]\nARG=[--help]')
  assert_eq "$label: subcommand --help untouched" "$expected" "$out"
}

# 语法静态检查
printf '=== Syntax Checks ===\n'
sh -n "$ROOT_DIR/bin/gay" "$ROOT_DIR/install.sh" "$ROOT_DIR/tests/test.sh"
PASS=$((PASS + 1))
printf '  [PASS] POSIX sh -n syntax\n'

node --check "$ROOT_DIR/bin/gay.mjs"
PASS=$((PASS + 1))
printf '  [PASS] Node --check syntax\n'

# 核心实现测试
run_suite_for "bin/gay (POSIX sh)" "$ROOT_DIR/bin/gay"
run_suite_for "bin/gay.mjs (Node)" "$ROOT_DIR/bin/gay.mjs"

# TTY 抹除触发行行为验证（需 python3 pty）
if command -v python3 >/dev/null 2>&1; then
  printf '=== Testing TTY Clear-Line ===\n'
  check_tty_clear() {
    name=$1
    expect_clear=$2
    runner=$3
    shift 3
    has_clear=$(PATH="$MOCK_BIN:$PATH" python3 - "$runner" "$@" << 'PY'
import os, pty, select, subprocess, sys

master, slave = pty.openpty()
proc = subprocess.Popen(sys.argv[1:], stdin=slave, stdout=slave, stderr=slave, close_fds=True)
os.close(slave)
buf = bytearray()
while True:
    r, _, _ = select.select([master], [], [], 2.0)
    if not r:
        break
    try:
        chunk = os.read(master, 4096)
    except OSError:
        break
    if not chunk:
        break
    buf.extend(chunk)
os.close(master)
proc.wait(timeout=5)
print("yes" if b"\x1b[1A\x1b[2K\r" in buf else "no")
PY
)
    assert_eq "$name" "$expect_clear" "$has_clear"
  }

  check_tty_clear "bin/gay TTY: clears on --yolo" "yes" "$ROOT_DIR/bin/gay" --yolo
  check_tty_clear "bin/gay TTY: skips clear on --help" "no" "$ROOT_DIR/bin/gay" --help
  check_tty_clear "bin/gay TTY: skips clear on subcommand" "no" "$ROOT_DIR/bin/gay" models
  check_tty_clear "bin/gay.mjs TTY: clears on --yolo" "yes" "$ROOT_DIR/bin/gay.mjs" --yolo
  check_tty_clear "bin/gay.mjs TTY: skips clear on -p" "no" "$ROOT_DIR/bin/gay.mjs" -p hi
fi

# 本地安装脚本测试（覆盖 --prefix 参数）
printf '=== Testing install.sh ===\n'
INSTALL_TARGET="$TMP_DIR/installed-bin"
PATH="$MOCK_BIN:$PATH" sh "$ROOT_DIR/install.sh" --prefix "$INSTALL_TARGET" >/dev/null
out=$(PATH="$MOCK_BIN:$PATH" "$INSTALL_TARGET/gay" --yolo)
expected=$(printf 'ARGC=1\nARG=[--dangerously-skip-permissions]')
assert_eq "install.sh: installed binary works" "$expected" "$out"

printf '\nSummary: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
