#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

STALE_PATH="/home/ZoneCNH-kernel""-governance-evidence"
ACCEPTANCE="module/kernel/ACCEPTANCE.md"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

mapfile -t markdown_files < <(git ls-files '*.md')
if ((${#markdown_files[@]} > 0)); then
  if grep -nF -- "$STALE_PATH" "${markdown_files[@]}"; then
    fail "stale kernel governance evidence path found in committed Markdown"
  fi
fi

grep -Fq 'cd <kernel-governance-evidence-worktree>' "$ACCEPTANCE" || \
  fail "$ACCEPTANCE must use the portable governance worktree placeholder"

grep -Fq '不是当前 Factory、GK-9 或 GK-10 通过证明' "$ACCEPTANCE" || \
  fail "$ACCEPTANCE must state it is not current Factory/GK proof"

grep -Fq '当前仍不得关闭 Factory / GK-9 / GK-10' "$ACCEPTANCE" || \
  fail "$ACCEPTANCE must preserve the current no-close gate status"

grep -Fq '不得仅凭 task 文档、历史状态文件或人工描述' "$ACCEPTANCE" || \
  fail "$ACCEPTANCE must forbid evidence promotion from task/history/manual descriptions alone"

grep -Fq 'task_id' "$ACCEPTANCE" || \
  fail "$ACCEPTANCE must name task IDs as runtime clues, not verified evidence"

grep -Fq '.omx/state/' "$ACCEPTANCE" || \
  fail "$ACCEPTANCE must name team runtime state as non-proof execution metadata"

echo "kernel-governance-lint: PASS"
