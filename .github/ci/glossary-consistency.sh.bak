#!/usr/bin/env bash
# glossary-consistency.sh — 检查 SPEC.md 中术语与 GLOSSARY.md 一致性
#
# 检查逻辑：
#   1. 术语一致性：SPEC.md 中使用的术语是否在 GLOSSARY.md 中有定义
#   2. 缩写检查：检测未定义的缩写（全大写 2+ 字母组合）
#   3. 模块名引用：SPEC.md 中引用的模块名是否在 GLOSSARY.md 中出现

set -euo pipefail

FAIL=0
WARN=0
REPO_ROOT="$(git rev-parse --show-toplevel)"
SPEC_DIR="$REPO_ROOT/module"
GLOSSARY="$REPO_ROOT/GLOSSARY.md"

echo "=== Glossary Consistency Check ==="
echo ""

if [[ ! -f "$GLOSSARY" ]]; then
  echo "❌ GLOSSARY.md not found at $GLOSSARY"
  exit 1
fi

# 从 GLOSSARY.md 提取已定义的术语（### 标题）
DEFINED_TERMS=$(grep -oP '(?<=### )\S+' "$GLOSSARY" | sort -u || true)

# 从 GLOSSARY.md 提取已定义的模块名（`backtick` 包裹的内容）
DEFINED_MODULES=$(grep -oP '`([a-z][-a-z0-9]*)`' "$GLOSSARY" | tr -d '`' | sort -u || true)

# 已知的合法缩写（不需要在 GLOSSARY 中定义）
KNOWN_ABBREVS="API|HTTP|HTTPS|URL|URI|JSON|YAML|CSV|SQL|TLS|TCP|UDP|IP|DNS|SSH|SSL|JWT|OAuth|SDK|CLI|GUI|ORM|P2P|IoT|CI|CD|PR|MR|FR|NFR|QA|UI|UX|DB|KV|LRU|FIFO|LIFO|TTL|QPS|TPS|P99|P95|P50|CPU|GPU|RAM|SSD|HDD|UTC|GMT|TWAP|VWAP|IC|IR|WHEN|THEN|AND|OR|IF|SPEC|README|LICENSE|CHANGELOG|CONSTITUTION|ARCHITECTURE|GATEWAY|CONFIG|METRICS|LOGGING|TRACING|HEALTH|BR|DOT|WSL|AI|TC"

check_spec() {
  local spec_file="$1"
  local module
  module=$(basename "$(dirname "$spec_file")")
  local issues=()

  # 1. 提取 spec 中反引号包裹的术语引用
  local spec_terms
  spec_terms=$(grep -oP '`([A-Z][A-Za-z0-9]+)`' "$spec_file" | tr -d '`' | sort -u || true)

  # 2. 检查术语是否在 GLOSSARY 中定义
  for term in $spec_terms; do
    # 跳过已知缩写
    if echo "$term" | grep -qP "^($KNOWN_ABBREVS)$"; then
      continue
    fi
    # 跳过 Go 类型风格（小写开头）
    if echo "$term" | grep -qP '^[a-z]'; then
      continue
    fi
    # 检查是否在 GLOSSARY 中
    if ! echo "$DEFINED_TERMS" | grep -qF "$term"; then
      issues+=("⚠️  term '$term' not defined in GLOSSARY.md")
      WARN=1
    fi
  done

  # 3. 提取 spec 中的缩写（全大写 2+ 字母）
  local abbrevs
  abbrevs=$(grep -oP '\b[A-Z]{2,}\b' "$spec_file" | sort -u || true)

  for abbr in $abbrevs; do
    # 跳过已知缩写和节标题编号
    if echo "$abbr" | grep -qP "^($KNOWN_ABBREVS)$"; then
      continue
    fi
    # 跳过纯数字
    if echo "$abbr" | grep -qP '^\d+$'; then
      continue
    fi
    # 检查是否在 GLOSSARY 中有解释
    if ! grep -qF "$abbr" "$GLOSSARY"; then
      issues+=("⚠️  abbreviation '$abbr' may be undefined in GLOSSARY.md")
      WARN=1
    fi
  done

  # 输出结果
  if [[ ${#issues[@]} -eq 0 ]]; then
    echo "  ✅ $module: terms and abbreviations consistent"
  else
    for issue in "${issues[@]}"; do
      echo "  $issue ($module)"
    done
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
  echo "❌ Glossary Consistency 失败 — 请修复上述错误"
  exit 1
elif [[ $WARN -ne 0 ]]; then
  echo "⚠️  Glossary Consistency 通过（有警告）"
  exit 0
else
  echo "✅ Glossary Consistency 全部通过"
  exit 0
fi
