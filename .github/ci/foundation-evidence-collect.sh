#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-unknown}"
OUTDIR="${FOUNDATION_EVIDENCE_OUTDIR:-release/foundation}"
MATRIX_PATH="${FOUNDATION_EVIDENCE_MATRIX:-module/FOUNDATION-DEPS.yaml}"
SOURCE_ROOT="${FOUNDATION_EVIDENCE_SOURCE_ROOT:-/home}"
OUTFILE="$OUTDIR/evidence-${VERSION}.json"

mkdir -p "$OUTDIR"

export VERSION
export MATRIX_PATH
export SOURCE_ROOT
export OUTFILE

python3 - <<'PY'
from __future__ import annotations

import datetime as dt
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError as exc:
    print("ERROR: PyYAML is required to read FOUNDATION-DEPS.yaml", file=sys.stderr)
    raise SystemExit(2) from exc


VERSION = os.environ["VERSION"]
MATRIX_PATH = Path(os.environ["MATRIX_PATH"])
SOURCE_ROOT = Path(os.environ["SOURCE_ROOT"])
OUTFILE = Path(os.environ["OUTFILE"])


def run(cmd: list[str], cwd: Path | None = None, timeout: int = 10) -> dict[str, object]:
    try:
        completed = subprocess.run(
            cmd,
            cwd=str(cwd) if cwd else None,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
        )
    except FileNotFoundError:
        return {"ok": False, "returncode": 127, "output": f"{cmd[0]} not found"}
    except subprocess.TimeoutExpired:
        return {"ok": False, "returncode": 124, "output": "timeout"}

    output = (completed.stdout or completed.stderr).strip()
    return {
        "ok": completed.returncode == 0,
        "returncode": completed.returncode,
        "output": output[:2000],
    }


def read_go_mod_module(repo: Path) -> str | None:
    go_mod = repo / "go.mod"
    if not go_mod.exists():
        return None

    for line in go_mod.read_text(encoding="utf-8", errors="replace").splitlines():
        stripped = line.strip()
        if stripped.startswith("module "):
            return stripped.split(None, 1)[1]
    return None


def read_go_version(repo: Path) -> str | None:
    go_mod = repo / "go.mod"
    if not go_mod.exists():
        return None

    for line in go_mod.read_text(encoding="utf-8", errors="replace").splitlines():
        stripped = line.strip()
        if stripped.startswith("go "):
            return stripped.split(None, 1)[1]
    return None


def require_count(repo: Path) -> int | None:
    go_mod = repo / "go.mod"
    if not go_mod.exists():
        return None

    count = 0
    for line in go_mod.read_text(encoding="utf-8", errors="replace").splitlines():
        stripped = line.strip()
        if stripped.startswith("require "):
            count += 1
    return count


def count_go_files(repo: Path) -> dict[str, int]:
    if not repo.exists():
        return {"total": 0, "test": 0, "production": 0}

    ignored = {".git", ".omx", "vendor"}
    total = 0
    test = 0

    for path in repo.rglob("*.go"):
        if any(part in ignored for part in path.parts):
            continue
        total += 1
        if path.name.endswith("_test.go"):
            test += 1

    return {"total": total, "test": test, "production": total - test}


def git_commit(repo: Path) -> str | None:
    result = run(["git", "rev-parse", "--short=12", "HEAD"], cwd=repo)
    if result["ok"]:
        return str(result["output"])
    return None


def git_dirty(repo: Path) -> bool | None:
    result = run(["git", "status", "--short"], cwd=repo)
    if not result["ok"]:
        return None
    return bool(str(result["output"]).strip())


def canonical_bytes(payload: dict[str, object]) -> bytes:
    return (
        json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        + "\n"
    ).encode("utf-8")


if not MATRIX_PATH.exists():
    print(f"ERROR: matrix not found: {MATRIX_PATH}", file=sys.stderr)
    raise SystemExit(2)

matrix = yaml.safe_load(MATRIX_PATH.read_text(encoding="utf-8"))
modules = matrix.get("modules", {})
allowed_deps = matrix.get("allowed_deps", {})
forbidden_edges = matrix.get("forbidden_foundation_edges", [])
go_baseline = str(matrix.get("go_baseline", ""))

module_evidence = {}
for name, spec in sorted(modules.items()):
    expected_module = spec.get("path")
    repo = SOURCE_ROOT / name
    source_status = "missing"
    actual_module = None
    commit = None
    dirty = None
    go_version = None
    go_files = {"total": 0, "test": 0, "production": 0}
    go_mod_require_count = None

    if repo.exists():
        actual_module = read_go_mod_module(repo)
        if actual_module == expected_module:
            source_status = "present"
            commit = git_commit(repo)
            dirty = git_dirty(repo)
            go_version = read_go_version(repo)
            go_files = count_go_files(repo)
            go_mod_require_count = require_count(repo)
        else:
            source_status = "module_mismatch"

    module_evidence[name] = {
        "expected_module": expected_module,
        "actual_module": actual_module,
        "layer": spec.get("layer"),
        "stdlib_only": bool(spec.get("stdlib_only", False)),
        "runtime_dependency": spec.get("runtime_dependency", True),
        "allowed_deps": allowed_deps.get(name, []),
        "source": str(repo),
        "source_status": source_status,
        "commit": commit,
        "dirty": dirty,
        "go_version": go_version,
        "go_baseline_match": go_version == go_baseline if go_version else None,
        "go_files": go_files,
        "go_mod_require_count": go_mod_require_count,
    }

body = {
    "schema_version": "foundation-evidence/v1",
    "version": VERSION,
    "timestamp": dt.datetime.now(dt.timezone.utc)
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z"),
    "matrix": {
        "path": str(MATRIX_PATH),
        "version": matrix.get("version"),
        "updated": str(matrix.get("updated")),
        "go_baseline": go_baseline,
        "module_count": len(modules),
        "forbidden_edge_count": len(forbidden_edges),
    },
    "modules": module_evidence,
    "provenance": {
        "repository": os.environ.get("GITHUB_REPOSITORY"),
        "workflow": os.environ.get("GITHUB_WORKFLOW"),
        "run_id": os.environ.get("GITHUB_RUN_ID"),
        "run_attempt": os.environ.get("GITHUB_RUN_ATTEMPT"),
        "ref": os.environ.get("GITHUB_REF"),
        "sha": os.environ.get("GITHUB_SHA"),
        "actor": os.environ.get("GITHUB_ACTOR"),
        "event_name": os.environ.get("GITHUB_EVENT_NAME"),
        "server_url": os.environ.get("GITHUB_SERVER_URL", "https://github.com"),
    },
    "runner": {
        "name": os.environ.get("RUNNER_NAME"),
        "os": os.environ.get("RUNNER_OS"),
        "arch": os.environ.get("RUNNER_ARCH"),
        "temp": os.environ.get("RUNNER_TEMP"),
        "tool_cache": os.environ.get("RUNNER_TOOL_CACHE"),
        "expected_labels": ["self-hosted", "Linux", "X64", "sre/foundation-l1"],
    },
    "toolchain": {
        "go": run(["go", "version"])["output"],
        "git": run(["git", "--version"])["output"],
        "python": run(["python3", "--version"])["output"],
    },
    "ci_contract": {
        "control_plane": "ZoneCNH/ZoneCNH GitHub Actions",
        "execution_plane": "ZoneCNH/sre deploy-contract workflow",
        "remote_execution_allowed_in_this_repo": False,
        "deploy_contract_preflight": ".github/ci/deploy-contract-preflight.sh",
    },
}

payload_digest = hashlib.sha256(canonical_bytes(body)).hexdigest()
payload = dict(body)
payload["artifact_digest"] = {
    "algorithm": "sha256",
    "subject": "canonical JSON payload before artifact_digest field",
    "value": payload_digest,
}

OUTFILE.write_text(
    json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
PY

FILE_DIGEST="$(sha256sum "$OUTFILE" | awk '{print $1}')"
printf '%s  %s\n' "$FILE_DIGEST" "$(basename "$OUTFILE")" > "$OUTFILE.sha256"

echo "Foundation evidence collected: $OUTFILE"
echo "Foundation evidence sha256: $FILE_DIGEST"
cat "$OUTFILE"
