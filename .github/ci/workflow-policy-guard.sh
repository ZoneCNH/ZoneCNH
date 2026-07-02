#!/usr/bin/env bash
# workflow-policy-guard.sh — enforce global CI/CD runner and deployment target rules

set -euo pipefail

python3 - <<'PY'
from pathlib import Path
import re
import sys

WORKFLOW_DIR = Path(".github/workflows")
# Accepted runner labels. Self-hosted runner was relabeled 2026-07-01 from
# `homepage` to `ci-governance` (commit 88239ab4) to match the label actually
# registered on sre host 94.72.124.39 (sre/bootstrap/hosts.env). `homepage`
# now survives only as a deploy target / repository concept (DEPLOY_TARGET),
# not as a runner label, so it is removed from this runner whitelist.
ACCEPTED_RUNNERS = [
    ["ubuntu-latest"],
    ["self-hosted", "Linux", "X64", "ci-governance"],
]
EXPECTED_REUSABLE_PREFIX = "./.github/workflows/"
EXPECTED_DEPLOY_CONTRACT = "ZoneCNH/sre/.github/workflows/deploy-contract.yml@main"
DEPLOY_HINT = re.compile(r"\b(deploy|deployment)\b|部署", re.IGNORECASE)
SRE_TARGET = "sre/"


def parse_inline_runs_on(raw):
    raw = raw.strip()
    if raw.startswith("[") and raw.endswith("]"):
        return [
            item.strip().strip("'\"")
            for item in raw[1:-1].split(",")
            if item.strip()
        ]
    return [raw.strip("'\"")]


def parse_runs_on(lines, index):
    line = lines[index]
    match = re.match(r"^(\s*)runs-on:\s*(.*?)(?:\s+#.*)?$", line)
    if not match:
        return None

    base_indent = len(match.group(1))
    raw = match.group(2).strip()
    line_no = index + 1

    if raw:
        return parse_inline_runs_on(raw), line_no, index + 1

    labels = []
    cursor = index + 1
    while cursor < len(lines):
        candidate = lines[cursor]
        stripped = candidate.strip()
        if not stripped or stripped.startswith("#"):
            cursor += 1
            continue

        indent = len(candidate) - len(candidate.lstrip(" "))
        if indent <= base_indent:
            break

        item = re.match(r"^\s*-\s*([^#]+?)(?:\s+#.*)?$", candidate)
        if not item:
            break

        labels.append(item.group(1).strip().strip("'\""))
        cursor += 1

    return labels, line_no, cursor


workflow_files = sorted(
    [
        *WORKFLOW_DIR.glob("*.yml"),
        *WORKFLOW_DIR.glob("*.yaml"),
    ]
)

if not workflow_files:
    print("ERROR: no workflow files found under .github/workflows", file=sys.stderr)
    sys.exit(1)

failures = []
runs_on_count = 0
reusable_count = 0

for path in workflow_files:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()

    cursor = 0
    while cursor < len(lines):
        parsed = parse_runs_on(lines, cursor)
        if parsed is None:
            cursor += 1
            continue

        labels, line_no, next_cursor = parsed
        runs_on_count += 1
        if labels not in ACCEPTED_RUNNERS:
            accepted_str = " or ".join(f"[{', '.join(r)}]" for r in ACCEPTED_RUNNERS)
            actual = f"[{', '.join(labels)}]" if labels else "<empty>"
            failures.append(
                f"{path}:{line_no}: runs-on must be one of {accepted_str}; found {actual}"
            )
        cursor = next_cursor

    for line_no, line in enumerate(lines, start=1):
        match = re.match(r"^ {4}uses:\s*([^#]+?)(?:\s+#.*)?$", line)
        if not match:
            continue

        reusable_count += 1
        target = match.group(1).strip().strip("'\"")
        if not (
            target.startswith(EXPECTED_REUSABLE_PREFIX)
            or target == EXPECTED_DEPLOY_CONTRACT
        ):
            failures.append(
                f"{path}:{line_no}: reusable workflow jobs must call "
                f"{EXPECTED_REUSABLE_PREFIX}* or {EXPECTED_DEPLOY_CONTRACT}; found {target}"
            )

    if DEPLOY_HINT.search(text) and SRE_TARGET not in text:
        failures.append(
            f"{path}: deployment workflows must declare the target machine pool as {SRE_TARGET}"
        )

if failures:
    print("Workflow Policy Guard failed:")
    for failure in failures:
        print(f"  - {failure}")
    sys.exit(1)

expected = " or ".join(f"[{', '.join(r)}]" for r in ACCEPTED_RUNNERS)
print(
    f"Workflow Policy Guard passed: {runs_on_count} runs-on entries use accepted runners ({expected}); "
    f"{reusable_count} reusable workflow jobs use repo-local or approved deploy-contract targets; "
    f"deployment workflows declare {SRE_TARGET} when applicable."
)
PY
