#!/usr/bin/env bash
set -euo pipefail

# runner-evidence.sh — 生成 runner 证据 JSON（CICD-001 §evidence）
# 输出：runner 身份、Go 环境、workflow 上下文

OUT="${1:-release/evidence/runner-evidence.json}"
SCHEMA_VERSION="${SCHEMA_VERSION:-zonecnh.runner-evidence.v1}"
BASELINE="${BASELINE:-BASELINE.yaml}"

mkdir -p "$(dirname "$OUT")"

# 从 BASELINE.yaml 提取基线配置
go_language=""
go_toolchain=""
ci_version=""
if [ -f "$BASELINE" ]; then
  go_language=$(grep -oP 'language:\s*"\K[^"]+' "$BASELINE" | head -1 || echo "unknown")
  go_toolchain=$(grep -oP 'toolchain:\s*"\K[^"]+' "$BASELINE" | head -1 || echo "unknown")
  ci_version=$(grep -oP 'ci_version:\s*"\K[^"]+' "$BASELINE" | head -1 || echo "unknown")
fi

cat > "$OUT" <<JSON
{
  "schema": "${SCHEMA_VERSION}",
  "runner_policy": "self_hosted_only",
  "github_hosted_allowed": false,
  "baseline": {
    "go_language": "${go_language:-unknown}",
    "go_toolchain": "${go_toolchain:-unknown}",
    "ci_version": "${ci_version:-unknown}"
  },
  "repository": "${GITHUB_REPOSITORY:-unknown}",
  "workflow": "${GITHUB_WORKFLOW:-unknown}",
  "run_id": "${GITHUB_RUN_ID:-unknown}",
  "run_attempt": "${GITHUB_RUN_ATTEMPT:-unknown}",
  "job": "${GITHUB_JOB:-unknown}",
  "sha": "${GITHUB_SHA:-unknown}",
  "ref": "${GITHUB_REF:-unknown}",
  "actor": "${GITHUB_ACTOR:-unknown}",
  "runner_name": "${RUNNER_NAME:-unknown}",
  "runner_os": "${RUNNER_OS:-unknown}",
  "runner_arch": "${RUNNER_ARCH:-unknown}",
  "go_version": "$(go version 2>/dev/null || echo 'not-installed')",
  "gotoolchain": "${GOTOOLCHAIN:-unset}",
  "cgo_enabled": "${CGO_ENABLED:-unset}",
  "go_flags": "${GOFLAGS:-unset}",
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON

echo "runner evidence written to $OUT"
