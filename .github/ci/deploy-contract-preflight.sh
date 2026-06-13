#!/usr/bin/env bash
set -euo pipefail

CONTRACT_FILE="${1:-release/manifest/sre-deploy-contract.json}"

if [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ]; then
  echo "ERROR: deploy contract preflight must not run as a pull_request deploy path" >&2
  exit 1
fi

python3 - "$CONTRACT_FILE" <<'PY'
import json
import os
import sys
from pathlib import Path, PurePosixPath

contract_file = Path(sys.argv[1])
require_evidence = os.environ.get("REQUIRE_DEPLOY_EVIDENCE") == "1"


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    sys.exit(1)


def require_string(data: dict, field: str) -> str:
    value = data.get(field)
    if not isinstance(value, str) or not value.strip():
        fail(f"{field} must be a non-empty string")
    return value


def require_release_path(data: dict, field: str, *, must_exist: bool) -> str:
    value = require_string(data, field)
    posix = PurePosixPath(value)
    if posix.is_absolute() or ".." in posix.parts:
        fail(f"{field} must be a relative path under release/manifest/")
    if len(posix.parts) < 3 or posix.parts[0] != "release" or posix.parts[1] != "manifest":
        fail(f"{field} must be under release/manifest/")
    if must_exist and not Path(value).is_file():
        fail(f"{field} does not exist: {value}")
    return value


if not contract_file.is_file():
    fail(f"deploy contract not found: {contract_file}")

try:
    contract = json.loads(contract_file.read_text(encoding="utf-8"))
except json.JSONDecodeError as exc:
    fail(f"deploy contract is not valid JSON: {exc}")

if not isinstance(contract, dict):
    fail("deploy contract must be a JSON object")

required_fields = [
    "contract_version",
    "release_ref",
    "environment",
    "target",
    "target_pool",
    "action",
    "dry_run",
    "manifest_path",
    "evidence_path",
    "execution_plane",
]
missing = [field for field in required_fields if field not in contract]
if missing:
    fail(f"missing required fields: {', '.join(missing)}")

contract_version = require_string(contract, "contract_version")
release_ref = require_string(contract, "release_ref")
if release_ref.lower() in {"unknown", "null", "none"}:
    fail("release_ref must be a concrete commit, tag, or release ref")

environment = require_string(contract, "environment")
if environment not in {"staging", "production"}:
    fail("environment must be staging or production")

target = require_string(contract, "target")
target_pool = require_string(contract, "target_pool")
if not target_pool.startswith("sre/"):
    fail("target_pool must start with sre/")

action = require_string(contract, "action")
if action != "deploy":
    fail("action must be deploy")

if not isinstance(contract["dry_run"], bool):
    fail("dry_run must be a boolean")

manifest_path = require_release_path(contract, "manifest_path", must_exist=True)
evidence_path = require_release_path(contract, "evidence_path", must_exist=require_evidence)

execution_plane = contract["execution_plane"]
if not isinstance(execution_plane, dict):
    fail("execution_plane must be an object")

expected_execution_plane = {
    "repository": "ZoneCNH/sre",
    "workflow": "ZoneCNH/sre/.github/workflows/deploy-contract.yml@main",
    "runner_pool": "sre/",
    "remote_execution_allowed_in_this_repo": False,
}
for key, expected in expected_execution_plane.items():
    actual = execution_plane.get(key)
    if actual != expected:
        fail(f"execution_plane.{key} must be {expected!r}, got {actual!r}")

print("deploy contract preflight PASS")
print(f"  contract_version: {contract_version}")
print(f"  release_ref: {release_ref}")
print(f"  environment: {environment}")
print(f"  target: {target}")
print(f"  target_pool: {target_pool}")
print(f"  manifest_path: {manifest_path}")
print(f"  evidence_path: {evidence_path}")
PY
