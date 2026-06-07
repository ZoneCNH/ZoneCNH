#!/usr/bin/env bash
# generate-release-manifest.sh — 生成发布时刻的系统快照
#
# 从 STATUS.md 提取组件统计，结合 git 信息生成 release manifest。
# 输出：release/manifest/release-manifest.json

set -euo pipefail

TAG="${GITHUB_REF_NAME:-$(git describe --tags --abbrev=0 2>/dev/null || echo 'unknown')}"
COMMIT_SHA="$(git rev-parse HEAD)"
COMMIT_SHORT="$(git rev-parse --short HEAD)"
GENERATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# ── 从 STATUS.md 提取统计 ──────────────────────────────────────
STATUS_FILE="STATUS.md"

if [ ! -f "$STATUS_FILE" ]; then
  echo "❌ 找不到 $STATUS_FILE"
  exit 1
fi

# 提取总览仪表盘中的数字
TOTAL=$(grep -oP '组件总数:\s*\K\d+' "$STATUS_FILE" | head -1)
EXISTING=$(grep -oP '已有:\s*\K\d+' "$STATUS_FILE" | head -1)
PLANNED=$(grep -oP '已创建:\s*\K\d+' "$STATUS_FILE" | head -1)
AVG_PROGRESS=$(grep -oP '平均进度:\s*\K\d+' "$STATUS_FILE" | head -1)
VERSIONED=$(grep -oP '有版本号\s*\K\d+' "$STATUS_FILE" | head -1)

# ── 提取 README.md 中的仓库数 ──────────────────────────────────
README_FILE="README.md"
REPO_COUNT=""
if [ -f "$README_FILE" ]; then
  REPO_COUNT=$(grep -oP 'github\.com/ZoneCNH/[a-zA-Z0-9._-]+' "$README_FILE" | sort -u | wc -l)
fi

# ── 文档路径 ────────────────────────────────────────────────────
ARCH_FILE="ARCHITECTURE.md"

# ── 文档文件统计 ───────────────────────────────────────────────
MD_COUNT=$(git ls-files '*.md' | wc -l)
MD_TOTAL_LINES=$(git ls-files '*.md' | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')

# ── 生成 JSON manifest ─────────────────────────────────────────
cat > release/manifest/release-manifest.json <<EOF
{
  "version": "${TAG}",
  "commit": "${COMMIT_SHA}",
  "commit_short": "${COMMIT_SHORT}",
  "generated_at": "${GENERATED_AT}",
  "stats": {
    "total_components": ${TOTAL:-0},
    "existing": ${EXISTING:-0},
    "planned": ${PLANNED:-0},
    "average_progress": ${AVG_PROGRESS:-0},
    "versioned": ${VERSIONED:-0},
    "repo_count": ${REPO_COUNT:-0},
    "markdown_files": ${MD_COUNT:-0},
    "markdown_total_lines": ${MD_TOTAL_LINES:-0}
  },
  "sources": {
    "status": "${STATUS_FILE}",
    "readme": "${README_FILE}",
    "architecture": "${ARCH_FILE}"
  }
}
EOF

# ── 生成 SHA256 校验 ───────────────────────────────────────────
sha256sum release/manifest/release-manifest.json \
  | awk '{print $1}' > release/manifest/release-manifest.json.sha256

echo "✅ Release manifest 已生成："
echo "   版本: ${TAG}"
echo "   提交: ${COMMIT_SHORT}"
echo "   组件: ${TOTAL:-?} (已有 ${EXISTING:-?} / 已创建 ${PLANNED:-?})"
echo "   进度: ${AVG_PROGRESS:-?}%"
echo "   仓库: ${REPO_COUNT:-?}"
echo "   文件: ${MD_COUNT:-?} 个 Markdown, ${MD_TOTAL_LINES:-?} 行"
