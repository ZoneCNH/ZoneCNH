#!/usr/bin/env bash
# grep-guard.sh — 禁止敏感内容和本地路径进入仓库
#
# 检查项：
#   1. .env / API key / secret / token / password 硬编码
#   2. .omc/ .omx/ 运行时目录（.claude/ .codex/ 已公开跟踪，不检查）
#   3. 127.0.0.1 / localhost / 0.0.0.0 本地地址
#   4. 本地绝对路径（/home/workspace/xxx, /Users/xxx, C:\xxx）

set -euo pipefail

FAIL=0
REPO_ROOT="$(git rev-parse --show-toplevel)"

echo "=== Grep Guard ==="
echo ""

# ── 扫描已跟踪和未忽略的未跟踪 .md 文件 ──
mapfile -t FILES < <(git ls-files --cached --others --exclude-standard '*.md')

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "⚠ 未发现 .md 文件，跳过"
  exit 0
fi

# ── 检查函数 ──────────────────────────────────────────────

check_pattern() {
  local label="$1"
  local pattern="$2"
  local found=0

  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      # 跳过 strikethrough（~~...~~）包裹的历史记录（如已修复的风险项）
      if echo "$line" | grep -qP '~~[^~]*(%s)[^~]*~~'; then
        continue
      fi
      echo "  ❌ $line"
      found=1
    fi
  done < <(grep -rnE "$pattern" "${FILES[@]}" 2>/dev/null | grep -v '~~' || true)

  if [[ $found -eq 1 ]]; then
    echo "  ↑ [$label] 发现违规内容"
    echo ""
    FAIL=1
  else
    echo "  ✅ $label — 通过"
    echo ""
  fi
}

# 带排除路径的检查函数（用于运行时目录等有合法引用的场景）
check_pattern_excluding() {
  local label="$1"
  local pattern="$2"
  shift 2
  local excludes=("$@")  # 排除的路径前缀列表
  local found=0

  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      # 跳过 strikethrough
      if echo "$line" | grep -qP '~~[^~]*(%s)[^~]*~~'; then
        continue
      fi
      # 检查是否匹配排除路径
      local skip=0
      for excl in "${excludes[@]}"; do
        if echo "$line" | grep -q "^${excl}"; then
          skip=1
          break
        fi
      done
      if [[ $skip -eq 1 ]]; then
        continue
      fi
      echo "  ❌ $line"
      found=1
    fi
  done < <(grep -rnE "$pattern" "${FILES[@]}" 2>/dev/null | grep -v '~~' || true)

  if [[ $found -eq 1 ]]; then
    echo "  ↑ [$label] 发现违规内容"
    echo ""
    FAIL=1
  else
    echo "  ✅ $label — 通过"
    echo ""
  fi
}

# ── 1. 敏感凭据 ──────────────────────────────────────────
echo "[1/4] 敏感凭据扫描"
check_pattern "API Key / Secret / Token / Password" \
  '(api[_-]?key|secret[_-]?key|access[_-]?token|private[_-]?key|password)\s*[:=]\s*["\x27]?[A-Za-z0-9+/=_-]{8,}'

# ── 2. 运行时目录 ────────────────────────────────────────
# 排除合法引用 .omc/.omx/.copilot/state 的架构文档和 agent 配置
echo "[2/4] 运行时目录检查"
check_pattern_excluding ".omc / .omx 运行时目录" \
  '(\.omc/|\.omx/|\.omc\b|\.omx\b)' \
  'AGENTS\.md' \
  'CONSTITUTION\.md' \
  'docs/ci-deployment\.md' \
  '\.config/goal/' \
  'docs/governance/' \
  'docs/goal/' \
  'docs/spec/' \
  'module/' \
  '\.claude/' \
  '\.codex/' \
  '\.copilot/' \
  '\.omc/'

# ── 3. 本地地址 ──────────────────────────────────────────
echo "[3/4] 本地地址检查"
check_pattern "127.0.0.1 / localhost / 0.0.0.0" \
  '(127\.0\.0\.1|localhost|0\.0\.0\.0|::1)'

# ── 4. 本地绝对路径 ──────────────────────────────────────
echo "[4/4] 本地绝对路径检查"
check_pattern_excluding "/home/workspace/xxx 或 /Users/xxx 或 C:\\xxx" \
  '(/home/[a-zA-Z0-9_-]+/|/Users/[a-zA-Z0-9_-]+/|[A-Z]:\\\\)' \
  'AGENTS\.md' \
  'ARCHITECTURE\.md' \
  '\.config/goal/' \
  'docs/governance/' \
  'docs/goal/' \
  'report/' \
  'docs/spec/' \
  'module/'

# ── 结果 ─────────────────────────────────────────────────
echo "=== 结果 ==="
if [[ $FAIL -ne 0 ]]; then
  echo "❌ Grep Guard 失败 — 发现上述违规内容，请修复后重试"
  exit 1
else
  echo "✅ Grep Guard 全部通过"
  exit 0
fi
