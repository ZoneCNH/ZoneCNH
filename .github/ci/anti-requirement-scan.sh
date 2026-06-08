#!/usr/bin/env bash
# anti-requirement-scan.sh — 扫描 module/ 中的代码片段是否违反 anti-requirements.md
#
# 检查逻辑：
#   1. log.Fatal / log.Fatalf / log.Fatalln — 库中禁止使用
#   2. os.Exit — 库中禁止使用
#   3. panic( — 非测试代码禁止使用
#   4. 硬编码配置 — 检测常见硬编码模式（端口、地址、超时）
#   5. 硬编码密钥 — 检测 API key / secret / password 模式
#   6. unsafe. — 禁止使用 unsafe 包

set -euo pipefail

FAIL=0
WARN=0
REPO_ROOT="$(git rev-parse --show-toplevel)"
SPEC_DIR="$REPO_ROOT/module"

echo "=== Anti-Requirement Scan ==="
echo ""

# 提取所有 spec 中代码块内容到临时文件，然后用 grep 扫描
# 这比逐行 read + grep 快得多
extract_code_blocks() {
  local file="$1"
  awk '/^```/{flag=!flag; next} flag{print NR": "$0}' "$file"
}

check_spec() {
  local spec_file="$1"
  local module
  module=$(basename "$(dirname "$spec_file")")
  local tmpfile
  tmpfile=$(mktemp)

  # 提取代码块内容（带行号）
  extract_code_blocks "$spec_file" > "$tmpfile"

  if [[ ! -s "$tmpfile" ]]; then
    rm -f "$tmpfile"
    echo "  ✅ $module: no code blocks to scan"
    return
  fi

  local found_issue=0

  # CRITICAL: log.Fatal
  while IFS= read -r match; do
    [[ -z "$match" ]] && continue
    echo "  ❌ log.Fatal 在库中禁止使用（anti-requirements 2.2） ($module:$match)"
    FAIL=1; found_issue=1
  done < <(grep -nP 'log\.Fatal' "$tmpfile" | grep -vP '^\d+:\s*(//|#)' || true)

  # CRITICAL: os.Exit
  while IFS= read -r match; do
    [[ -z "$match" ]] && continue
    echo "  ❌ os.Exit 在库中禁止使用（anti-requirements 2.2） ($module:$match)"
    FAIL=1; found_issue=1
  done < <(grep -nP 'os\.Exit' "$tmpfile" | grep -vP '^\d+:\s*(//|#)' || true)

  # HIGH: panic(
  while IFS= read -r match; do
    [[ -z "$match" ]] && continue
    echo "  ❌ panic() 在非测试代码中禁止使用（anti-requirements 2.2） ($module:$match)"
    FAIL=1; found_issue=1
  done < <(grep -nP 'panic\(' "$tmpfile" | grep -vP '^\d+:\s*(//|#)' || true)

  # HIGH: unsafe.
  while IFS= read -r match; do
    [[ -z "$match" ]] && continue
    echo "  ❌ unsafe 包禁止使用（anti-requirements 2.4） ($module:$match)"
    FAIL=1; found_issue=1
  done < <(grep -nP 'unsafe\.' "$tmpfile" | grep -vP '^\d+:\s*(//|#)' || true)

  # MEDIUM: 硬编码地址/端口
  while IFS= read -r match; do
    [[ -z "$match" ]] && continue
    echo "  ⚠️  疑似硬编码地址/端口（anti-requirements 2.3） ($module:$match)"
    WARN=1
  done < <(grep -nP '(localhost|127\.0\.0\.1|0\.0\.0\.0):[0-9]' "$tmpfile" | grep -vP '^\d+:\s*(//|#)' || true)

  # CRITICAL: 疑似密钥
  while IFS= read -r match; do
    [[ -z "$match" ]] && continue
    echo "  ❌ 疑似硬编码密钥（anti-requirements 2.4） ($module:$match)"
    FAIL=1; found_issue=1
  done < <(grep -nP '(AKIA[0-9A-Z]{16}|sk-[a-zA-Z0-9]{20,})' "$tmpfile" || true)

  # HIGH: 硬编码密码/密钥赋值
  while IFS= read -r match; do
    [[ -z "$match" ]] && continue
    echo "  ❌ 疑似硬编码密钥赋值（anti-requirements 2.4） ($module:$match)"
    FAIL=1; found_issue=1
  done < <(grep -niP "(password|api[_-]?key|secret)\s*[:=]\s*[\"']" "$tmpfile" | grep -vP '^\d+:\s*(//|#)' || true)

  rm -f "$tmpfile"

  if [[ $found_issue -eq 0 ]]; then
    echo "  ✅ $module: no anti-requirement violations found"
  fi
}

# 遍历所有 spec
for spec_file in "$SPEC_DIR"/*/SPEC.md; do
  if [[ -f "$spec_file" ]]; then
    check_spec "$spec_file"
  fi
done

echo ""
echo "=== 结果 ==="
if [[ $FAIL -ne 0 ]]; then
  echo "❌ Anti-Requirement Scan 失败 — 请修复上述违规"
  exit 1
elif [[ $WARN -ne 0 ]]; then
  echo "⚠️  Anti-Requirement Scan 通过（有警告）"
  exit 0
else
  echo "✅ Anti-Requirement Scan 全部通过"
  exit 0
fi
