#!/usr/bin/env bash
# generate-release-manifest.sh — 生成发布时刻的系统快照
#
# 从 STATUS.md 提取组件统计，结合 git 信息生成 release manifest。
# 输出：
# - release/manifest/release-manifest.json
# - release/manifest/sre-deploy-contract.json

set -euo pipefail

TAG="${GITHUB_REF_NAME:-$(git describe --tags --abbrev=0 2>/dev/null || echo 'unknown')}"
COMMIT_SHA="$(git rev-parse HEAD)"
COMMIT_SHORT="$(git rev-parse --short HEAD)"
GENERATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
DEPLOY_ENVIRONMENT="${DEPLOY_ENVIRONMENT:-staging}"
DEPLOY_TARGET="${DEPLOY_TARGET:-homepage}"
DEPLOY_TARGET_POOL="${DEPLOY_TARGET_POOL:-sre/homepage}"

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

# ── Foundation trust evidence ─────────────────────────────────
FOUNDATION_STATUS_FILE=".foundationx/status/index.json"
FOUNDATION_BLOCKERS_FILE=".foundationx/blockers.json"
FOUNDATION_CONTRACT_FILE=".foundationx/repo-contract.json"
FOUNDATION_TRUST_JSON="$(
  python3 - "$FOUNDATION_STATUS_FILE" "$FOUNDATION_BLOCKERS_FILE" "$FOUNDATION_CONTRACT_FILE" <<'PY'
import json
import sys
from collections import Counter
from pathlib import Path

status_path, blockers_path, contract_path = map(Path, sys.argv[1:4])
missing_sources = [str(path) for path in (status_path, blockers_path, contract_path) if not path.exists()]

def load_json(path):
    if not path.exists():
        return {}
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)

status = load_json(status_path)
blockers = load_json(blockers_path)
contract = load_json(contract_path)
summary = status.get("summary", {})
blocker_items = blockers.get("blockers", [])
open_blockers = [item for item in blocker_items if item.get("status") == "open"]
by_severity = Counter(item.get("severity", "unspecified") for item in open_blockers)
by_module = Counter(item.get("module", "unspecified") for item in open_blockers)
by_category = Counter(item.get("category", "unspecified") for item in open_blockers)
projection_guards = contract.get("projection_guards", {})
reason_codes = contract.get("reason_codes", {})

trust = {
    "available": not missing_sources,
    "summary": {
        "source": str(status_path),
        "schema_version": status.get("schema_version"),
        "generated_at": status.get("generated_at"),
        "total_modules": summary.get("total_modules", status.get("total_modules", 0)),
        "spec_complete": summary.get("spec_complete", 0),
        "impl_complete": summary.get("impl_complete", 0),
        "release_published": summary.get("release_published", 0),
        "live_integration": summary.get("live_integration", 0),
        "factory_grade": summary.get("factory_grade", 0),
    },
    "open_blockers": {
        "source": str(blockers_path),
        "total": len(open_blockers),
        "by_severity": dict(sorted(by_severity.items())),
        "by_module": dict(sorted(by_module.items())),
        "by_category": dict(sorted(by_category.items())),
        "ids": [item.get("id") for item in open_blockers],
    },
    "projection_guard": {
        "source": str(contract_path),
        "contract_version": contract.get("contract_version"),
        "public_docs": projection_guards.get("public_docs", []),
        "release_manifest": projection_guards.get("release_manifest"),
        "reason_code": "policy_contract_projection_drift",
        "reason_present": "policy_contract_projection_drift" in reason_codes.get("policy_failures", []),
    },
    "claim_policy": {
        "audit_status_factory_grade_proof": False,
        "audit_status_role": "projection consistency guard only; not factory-grade proof",
        "factory_grade_requires": [
            "foundation status summary",
            "open blocker review",
            "projection guard",
            "xlibgate trust evidence",
        ],
    },
    "missing_sources": missing_sources,
}

print(json.dumps(trust, ensure_ascii=False, sort_keys=True, separators=(",", ":")))
PY
)"

# ── 生成 JSON manifest ─────────────────────────────────────────
mkdir -p release/manifest

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
    "architecture": "${ARCH_FILE}",
    "foundation_status": "${FOUNDATION_STATUS_FILE}",
    "foundation_blockers": "${FOUNDATION_BLOCKERS_FILE}",
    "foundation_contract": "${FOUNDATION_CONTRACT_FILE}"
  },
  "foundation_trust": ${FOUNDATION_TRUST_JSON}
}
EOF

# ── 生成 SHA256 校验 ───────────────────────────────────────────
sha256sum release/manifest/release-manifest.json \
  | awk '{print $1}' > release/manifest/release-manifest.json.sha256

cat > release/manifest/sre-deploy-contract.json <<EOF
{
  "contract_version": "2026-06-13",
  "release_ref": "${COMMIT_SHA}",
  "release_version": "${TAG}",
  "environment": "${DEPLOY_ENVIRONMENT}",
  "target": "${DEPLOY_TARGET}",
  "target_pool": "${DEPLOY_TARGET_POOL}",
  "action": "deploy",
  "dry_run": true,
  "manifest_path": "release/manifest/release-manifest.json",
  "evidence_path": "release/manifest/goal-release-gate.json",
  "execution_plane": {
    "repository": "ZoneCNH/sre",
    "workflow": "ZoneCNH/sre/.github/workflows/deploy-contract.yml@main",
    "runner_pool": "sre/",
    "remote_execution_allowed_in_this_repo": false
  }
}
EOF

sha256sum release/manifest/sre-deploy-contract.json \
  | awk '{print $1}' > release/manifest/sre-deploy-contract.json.sha256

echo "✅ Release manifest 已生成："
echo "   版本: ${TAG}"
echo "   提交: ${COMMIT_SHORT}"
echo "   组件: ${TOTAL:-?} (已有 ${EXISTING:-?} / 已创建 ${PLANNED:-?})"
echo "   进度: ${AVG_PROGRESS:-?}%"
echo "   仓库: ${REPO_COUNT:-?}"
echo "   文件: ${MD_COUNT:-?} 个 Markdown, ${MD_TOTAL_LINES:-?} 行"
echo "   SRE 合同: ${DEPLOY_TARGET_POOL} / ${DEPLOY_ENVIRONMENT} / dry_run=true"
echo "   Foundation trust: summary/open blockers/projection guard embedded"
