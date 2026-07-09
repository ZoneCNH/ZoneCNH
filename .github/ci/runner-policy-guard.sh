#!/usr/bin/env bash
set -euo pipefail

# runner-policy-guard.sh — 强制 self-hosted runner policy (CICD-001)
# 扫描 .github/workflows/* 和 module/*/ci-workflow.yaml，禁止 GitHub-hosted runner。
# 规则来源：BASELINE.yaml §ci_cd.forbidden_runs_on

ROOT="${1:-.}"
KNOWN_POOLS_FILE="${KNOWN_POOLS_FILE:-docs/sre/RUNNER-POOLS.yaml}"
violations=0

echo "== ZoneCNH Runner Policy Guard =="
echo "root=$ROOT"
echo

extract_pools() {
  if [ -f "$KNOWN_POOLS_FILE" ]; then
    grep -E '^  sre/' "$KNOWN_POOLS_FILE" | sed 's/:.*//' | xargs -n1 || true
  fi
}

is_known_pool() {
  local pool="$1"
  extract_pools | grep -qx "$pool"
}

# 扫描范围：repo workflow + module ci-workflow（排除 sre/ 独立项目）
workflow_files=$(
  find "$ROOT" \
    \( \
      -path "*/.github/workflows/*.yml" \
      -o -path "*/.github/workflows/*.yaml" \
      -o -path "*/module/*/ci-workflow.yaml" \
    \) \
    -not -path "*/sre/*" \
    -not -path "*/.git/*" \
    -type f 2>/dev/null | sort || true
)

if [ -z "${workflow_files}" ]; then
  echo "WARN: no workflow files found"
  exit 0
fi

for file in $workflow_files; do
  echo "checking: $file"

  # 1. 禁止 GitHub-hosted runner 标签
  if grep -nE 'runs-on:[[:space:]]*(ubuntu|windows|macos)-' "$file" 2>/dev/null; then
    echo "  ERROR: GitHub-hosted runner label is forbidden: $file"
    violations=$((violations + 1))
  fi

  # 2. 禁止 explicit GitHub-hosted runner 字符串（含 ubuntu-22.04/24.04 等）
  if grep -nE 'ubuntu-latest|windows-latest|macos-latest|ubuntu-22\.04|ubuntu-24\.04|windows-2022|macos-14' "$file" 2>/dev/null; then
    echo "  ERROR: forbidden hosted runner reference found: $file"
    violations=$((violations + 1))
  fi

  # 3. 逐行检查 runs-on: 要求 self-hosted + sre/*
  while IFS= read -r line; do
    line_no="$(echo "$line" | cut -d: -f1)"
    line_text="$(echo "$line" | cut -d: -f2-)"

    if ! echo "$line_text" | grep -q 'self-hosted'; then
      echo "  ERROR: runs-on must include self-hosted at $file:$line_no"
      echo "    $line_text"
      violations=$((violations + 1))
    fi

    if ! echo "$line_text" | grep -qE 'sre/'; then
      echo "  ERROR: runs-on must include sre/* pool at $file:$line_no"
      echo "    $line_text"
      violations=$((violations + 1))
    fi
  done < <(grep -nE 'runs-on:' "$file" 2>/dev/null || true)

  # 4. 校验 pool 存在于 RUNNER-POOLS.yaml
  pools=$(grep -oE 'sre/[a-zA-Z0-9_-]+' "$file" 2>/dev/null | sort -u || true)
  for pool in $pools; do
    if [ -f "$KNOWN_POOLS_FILE" ] && ! is_known_pool "$pool"; then
      echo "  ERROR: unknown runner pool $pool in $file"
      violations=$((violations + 1))
    fi
  done

  # 5. 禁止业务仓库内联部署命令
  if grep -nE '(^|[[:space:]|;&])(ssh|scp|rsync|kubectl|helm|systemctl)([[:space:]]|$)|docker[[:space:]]+compose' "$file" 2>/dev/null; then
    echo "  ERROR: direct deployment/remote command is forbidden in workflow: $file"
    violations=$((violations + 1))
  fi

done

if [ "$violations" -gt 0 ]; then
  echo
  echo "runner policy FAILED: $violations violation(s)"
  exit 1
fi

echo
echo "runner policy PASSED"
