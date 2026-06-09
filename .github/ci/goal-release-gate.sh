#!/usr/bin/env bash
# goal-release-gate.sh — hard-block release until Goal control plane is releasable.
#
# Usage: bash .github/ci/goal-release-gate.sh [repo-root]
# Output: release/manifest/goal-release-gate.json on PASS.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROOT="${1:-$DEFAULT_ROOT}"
VALIDATOR_SCRIPT="${GOAL_VALIDATOR_SCRIPT:-$ROOT/docs/goal/tools/goal-validate.py}"

cd "$ROOT"
mkdir -p release/manifest

python3 "$VALIDATOR_SCRIPT" --root . --mode strict --format text

GOAL_VALIDATOR_SCRIPT="$VALIDATOR_SCRIPT" python3 - <<'PY'
from __future__ import annotations

import importlib.util
import json
import os
import re
import subprocess
import sys
from pathlib import Path

root = Path.cwd()
validator_path = Path(os.environ["GOAL_VALIDATOR_SCRIPT"]).resolve()
spec = importlib.util.spec_from_file_location("goal_validate", validator_path)
if spec is None or spec.loader is None:
    print(f"GRG-VALIDATOR-LOAD: cannot load {validator_path}", file=sys.stderr)
    sys.exit(1)

goal_validate = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = goal_validate
spec.loader.exec_module(goal_validate)

workflow_path = root / ".github/workflows/goal-ci.yml"
rules_path = root / ".config/goal/schema/rules.yaml"
gates_path = root / ".config/goal/gates/state.yaml"
risks_path = root / ".config/goal/registry/risks.yaml"
evidence_dir = root / ".config/goal/evidence"
manifest_path = root / "release/manifest/goal-release-gate.json"

errors: list[tuple[str, object]] = []

gates = goal_validate.parse_gates(gates_path)
risks = goal_validate.parse_risks(risks_path)
g10 = gates.get("G10", {})
g10_result = g10.get("result") if isinstance(g10.get("result"), dict) else {}
g10_status = goal_validate.normalize_status(g10.get("status"))
g10_verdict = goal_validate.normalize_status(g10_result.get("verdict"))

if g10_status != "PASS" or g10_verdict != "PASS":
    errors.append(("GRG-G10-NOT-PASS", {"status": g10_status, "result_verdict": g10_verdict}))

open_release_blocking_risks = {
    **goal_validate.registry_open_release_blocking_risks(risks),
    **goal_validate.gate_open_release_blocking_risks(gates),
}
if open_release_blocking_risks:
    errors.append(("GRG-OPEN-RELEASE-RISK", sorted(open_release_blocking_risks)))

evidence_files = []
if evidence_dir.exists():
    evidence_files = sorted(
        path.relative_to(root).as_posix()
        for path in evidence_dir.rglob("*.md")
        if path.is_file()
    )
if not evidence_files:
    errors.append(("GRG-EVIDENCE-MISSING", ".config/goal/evidence/**/*.md"))

job_ids = set()
if workflow_path.exists():
    workflow_text = workflow_path.read_text(encoding="utf-8")
    job_ids = set(re.findall(r"^  ([A-Za-z0-9_-]+):\s*$", workflow_text, re.MULTILINE))
required_jobs = goal_validate.parse_ci_required_jobs(rules_path)
if "goal-validator" not in job_ids or "goal-validator" not in required_jobs:
    errors.append(
        (
            "GRG-GOAL-CI-CONTRACT",
            {
                "workflow_jobs": sorted(job_ids),
                "required_jobs": sorted(required_jobs),
            },
        )
    )

if errors:
    print("Goal release gate failed:")
    for code, detail in errors:
        print(f"- {code}: {detail}")
    sys.exit(1)

try:
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
except Exception:
    commit = ""

manifest = {
    "verdict": "PASS",
    "commit": commit,
    "g10": {
        "status": g10_status,
        "result_verdict": g10_verdict,
    },
    "open_release_blocking_risks": [],
    "evidence": {
        "count": len(evidence_files),
        "files": evidence_files,
    },
    "goal_ci": {
        "workflow": ".github/workflows/goal-ci.yml",
        "required_job": "goal-validator",
    },
}
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Goal release gate passed: wrote {manifest_path.relative_to(root)}")
PY
