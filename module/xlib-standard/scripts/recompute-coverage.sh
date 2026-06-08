#!/usr/bin/env bash
# recompute-coverage.sh — 重算 COVERAGE-MANIFEST.md 中的 sha256 前缀
# 用法：cd <upstream:xlib-standard> && bash scripts/recompute-coverage.sh
set -euo pipefail

echo "=== commit / tree sha ==="
COMMIT=$(git rev-parse HEAD)
TREE=$(git rev-parse HEAD^{tree})
echo "upstream:commit = ${COMMIT}"
echo "upstream:tree   = ${TREE}"

echo ""
echo "=== 文件级 sha256 (前 16 hex) ==="
{ find .worktree -maxdepth 1 -name "*.md" -type f -printf '%p\n' 2>/dev/null; \
  find docs -type f -name "*.md" 2>/dev/null; } \
  | sort \
  | xargs sha256sum \
  | awk '{print substr($1,1,16)"  <upstream:xlib-standard>/"$2}'

echo ""
echo "=== 外部 Downloads sha256（如路径存在） ==="
EXT_DIR="${EXTERNAL_DOWNLOADS:-}"
if [[ -n "${EXT_DIR}" && -d "${EXT_DIR}/xlib-standard" ]]; then
  find "${EXT_DIR}/xlib-standard" -type f | sort \
    | xargs sha256sum \
    | awk -F/ '{print substr($1,1,16)"  <external:Downloads>/"$NF}'
else
  echo "(EXTERNAL_DOWNLOADS 未设置或目录不存在，跳过)"
fi

echo ""
echo "=== 完成 ==="
echo "请将输出与 COVERAGE-MANIFEST.md 中的 sha256 表逐行比对。"
