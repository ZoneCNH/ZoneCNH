#!/usr/bin/env python3
"""Goal control-plane validator.

The validator intentionally uses only the Python standard library so it can run
in bootstrap CI before project dependencies are installed.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


AREAS = ("runtime", "matrix", "gate", "risk", "consistency")

EDGE_REQUIRED_FIELDS = [
    "source_id",
    "target_id",
    "relation",
    "status",
    "evidence_id",
    "gate_id",
    "owner",
    "updated_at",
]
EDGE_NON_EMPTY_FIELDS = set(EDGE_REQUIRED_FIELDS) - {"evidence_id"}
EDGE_ALLOWED_FIELDS = set(EDGE_REQUIRED_FIELDS) | {"drop_reason"}
EDGE_LEGACY_FIELDS = {"goal_id", "requirement_id", "evidence_ids"}
EDGE_RELATIONS = {
    "decomposes_to",
    "contains",
    "accepted_by",
    "planned_by",
    "implemented_by",
    "prompted_by",
    "verified_by",
    "evidenced_by",
}
EDGE_STATUSES = {
    "Unmapped",
    "Mapped",
    "Linked",
    "Verified",
    "Dropped",
    "Drifted",
    "Stale",
    "Blocked",
    "Changed",
}

GATE_IDS = [f"G{index}" for index in range(12)]
GATE_TERMINAL_STATUSES = {"PASS", "PASS_WITH_RISK", "FAIL", "BLOCKED"}
PASS_WITH_RISK_DISALLOWED = {"G6", "G10"}
PASS_WITH_RISK_REQUIRED = {
    "risk_id",
    "mitigation",
    "due_at",
    "release_blocking",
    "status",
}
PASS_WITH_RISK_OWNER_FIELDS = {"risk_owner", "owner"}

OPEN_STATUSES = {"OPEN"}
RELEASED_STATUSES = {"RELEASED"}
DONE_PIPELINE_STATES = {"DONE"}
RISK_ID_PATTERN = re.compile(r"^RISK-GOAL-\d{8}-\d{3}-\d{3}$")
RISK_ID_EXPECTED = "RISK-GOAL-YYYYMMDD-NNN-NNN"
GATE_ID_EXTRACTORS = (
    re.compile(r"^\s*-\s+gate_id:\s*(G\d+)\s*$"),
    re.compile(r"^  (G\d+):\s*$"),
)
RISK_ID_EXTRACTORS = (re.compile(r"^\s*-\s+risk_id:\s*(.+?)\s*$"),)


@dataclass
class Violation:
    id: str
    severity: str
    area: str
    path: str
    message: str
    expected: str
    actual: str


class Report:
    def __init__(self) -> None:
        self.violations: list[Violation] = []

    def error(
        self,
        id_: str,
        area: str,
        path: Path | str,
        message: str,
        expected: str,
        actual: Any,
    ) -> None:
        self.violations.append(
            Violation(
                id=id_,
                severity="ERROR",
                area=area,
                path=str(path),
                message=message,
                expected=expected,
                actual=format_actual(actual),
            )
        )

    @property
    def error_count(self) -> int:
        return sum(1 for item in self.violations if item.severity == "ERROR")

    @property
    def warn_count(self) -> int:
        return sum(1 for item in self.violations if item.severity == "WARN")


def format_actual(value: Any) -> str:
    if value is None:
        return "<missing>"
    if isinstance(value, (list, tuple, set)):
        return ", ".join(str(item) for item in value) if value else "<empty>"
    if isinstance(value, dict):
        return json.dumps(value, ensure_ascii=False, sort_keys=True)
    text = str(value)
    return text if text else "<empty>"


def clean_value(raw: str) -> str:
    value = raw.strip()
    if len(value) >= 2 and value[0] in {"'", '"'}:
        quote = value[0]
        end = value.rfind(quote)
        if end > 0:
            return value[1:end]
    value = value.split("#", 1)[0].strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        value = value[1:-1]
    return value


def parse_inline_list(value: str) -> list[str]:
    value = clean_value(value)
    if value.startswith("[") and value.endswith("]"):
        inner = value[1:-1].strip()
        if not inner:
            return []
        return [clean_value(part) for part in inner.split(",") if clean_value(part)]
    return [value] if value else []


def parse_scalar(raw_value: str) -> str | list[str]:
    value = clean_value(raw_value)
    if value.startswith("[") and value.endswith("]"):
        return parse_inline_list(value)
    return value


def normalize_status(value: Any) -> str:
    return str(value or "").strip().upper()


def is_truthy(value: Any) -> bool:
    return normalize_status(value) in {"TRUE", "YES", "Y", "1"}


def read_lines(path: Path) -> list[str]:
    return path.read_text(encoding="utf-8").splitlines()


def path_at(path: Path, line: int | None) -> str:
    return f"{path}:{line}" if line else str(path)


def find_duplicate_ids(path: Path, extractors: tuple[re.Pattern[str], ...]) -> dict[str, list[int]]:
    if not path.exists():
        return {}

    seen: dict[str, list[int]] = {}
    for line_number, raw_line in enumerate(read_lines(path), start=1):
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue

        for extractor in extractors:
            match = extractor.match(raw_line)
            if match:
                value = clean_value(match.group(1))
                if value:
                    seen.setdefault(value, []).append(line_number)
                break

    return {value: lines for value, lines in seen.items() if len(lines) > 1}


def parse_ci_required_jobs(path: Path) -> set[str]:
    if not path.exists():
        return set()

    required_jobs: set[str] = set()
    in_ci = False
    in_required_jobs = False

    for raw_line in read_lines(path):
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue

        top_level = re.match(r"^([A-Za-z0-9_]+):\s*(.*)$", raw_line)
        if top_level:
            in_ci = top_level.group(1) == "ci"
            in_required_jobs = False
            continue

        if not in_ci:
            continue

        ci_field = re.match(r"^  ([A-Za-z0-9_]+):\s*(.*)$", raw_line)
        if ci_field:
            key, raw_value = ci_field.group(1), ci_field.group(2)
            in_required_jobs = key == "required_jobs"
            if in_required_jobs:
                required_jobs.update(parse_inline_list(raw_value))
            continue

        if in_required_jobs:
            item = re.match(r"^\s*-\s*(.+?)\s*$", raw_line)
            if item:
                required_jobs.add(clean_value(item.group(1)))

    return required_jobs


def parse_matrix(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []

    rows: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None
    current_key: str | None = None

    for line_number, raw_line in enumerate(read_lines(path), start=1):
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue

        start = re.match(r"^\s*-\s+([A-Za-z_]+):\s*(.*)$", raw_line)
        if start:
            if current:
                rows.append(current)
            key, value = start.group(1), parse_scalar(start.group(2))
            current = {"_line": line_number, "_keys": [key], key: value}
            current_key = key
            continue

        if current is None:
            continue

        field = re.match(r"^\s+([A-Za-z_]+):\s*(.*)$", raw_line)
        if field:
            key, value = field.group(1), parse_scalar(field.group(2))
            current[key] = value
            current.setdefault("_keys", []).append(key)
            current_key = key
            continue

        item = re.match(r"^\s+-\s*(.+?)\s*$", raw_line)
        if item and current_key:
            current.setdefault(current_key, [])
            if not isinstance(current[current_key], list):
                current[current_key] = []
            current[current_key].append(clean_value(item.group(1)))

    if current:
        rows.append(current)
    return rows


def parse_gates(path: Path) -> dict[str, dict[str, Any]]:
    if not path.exists():
        return {}

    gates: dict[str, dict[str, Any]] = {}
    current: dict[str, Any] | None = None
    section: str | None = None

    for line_number, raw_line in enumerate(read_lines(path), start=1):
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue

        start = re.match(r"^\s*-\s+gate_id:\s*(G\d+)\s*$", raw_line)
        if start:
            gate_id = start.group(1)
            current = {"gate_id": gate_id, "_line": line_number, "risk": {}, "result": {}}
            gates[gate_id] = current
            section = None
            continue

        mapping_start = re.match(r"^  (G\d+):\s*$", raw_line)
        if mapping_start:
            gate_id = mapping_start.group(1)
            current = {"gate_id": gate_id, "_line": line_number, "risk": {}, "result": {}}
            gates[gate_id] = current
            section = None
            continue

        if current is None:
            continue

        top_field = re.match(r"^    ([A-Za-z_]+):(?:\s*(.*))?$", raw_line)
        if top_field:
            key = top_field.group(1)
            value = clean_value(top_field.group(2) or "")
            if key in {"risk", "result"}:
                current.setdefault(key, {})
                section = key
            else:
                current[key] = value
                section = None
            continue

        nested = re.match(r"^      ([A-Za-z_]+):\s*(.*)$", raw_line)
        if nested and section in {"risk", "result"}:
            key, value = nested.group(1), parse_scalar(nested.group(2))
            current.setdefault(section, {})[key] = value

    return gates


def parse_risks(path: Path) -> dict[str, dict[str, Any]]:
    if not path.exists():
        return {}

    risks: dict[str, dict[str, Any]] = {}
    current: dict[str, Any] | None = None

    for line_number, raw_line in enumerate(read_lines(path), start=1):
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue

        start = re.match(r"^\s*-\s+risk_id:\s*(.+?)\s*$", raw_line)
        if start:
            risk_id = clean_value(start.group(1))
            current = {"risk_id": risk_id, "_line": line_number}
            risks[risk_id] = current
            continue

        if current is None:
            continue

        field = re.match(r"^    ([A-Za-z_]+):\s*(.*)$", raw_line)
        if field:
            current[field.group(1)] = parse_scalar(field.group(2))

    return risks


def parse_releases(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []

    releases: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None

    for line_number, raw_line in enumerate(read_lines(path), start=1):
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue

        start = re.match(r"^\s*-\s+release_id:\s*(.+?)\s*$", raw_line)
        if start:
            if current:
                releases.append(current)
            current = {"release_id": clean_value(start.group(1)), "_line": line_number}
            continue

        if current is None:
            continue

        field = re.match(r"^    ([A-Za-z_]+):\s*(.*)$", raw_line)
        if field:
            current[field.group(1)] = parse_scalar(field.group(2))

    if current:
        releases.append(current)
    return releases


def parse_pipeline(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}

    current: dict[str, Any] | None = None

    for line_number, raw_line in enumerate(read_lines(path), start=1):
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue

        start = re.match(r"^\s*-\s+goal_id:\s*(.+?)\s*$", raw_line)
        if start and current is None:
            current = {"goal_id": clean_value(start.group(1)), "_line": line_number}
            continue
        if start and current is not None:
            break

        if current is None:
            continue

        field = re.match(r"^    ([A-Za-z_]+):\s*(.*)$", raw_line)
        if field:
            current[field.group(1)] = parse_scalar(field.group(2))

    return current or {}


def active_gitignore_lines(path: Path) -> list[tuple[int, str]]:
    if not path.exists():
        return []
    active: list[tuple[int, str]] = []
    for line_number, raw_line in enumerate(read_lines(path), start=1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        active.append((line_number, line))
    return active


def check_runtime(root: Path, report: Report) -> None:
    gitignore = root / ".gitignore"
    if not gitignore.exists():
        report.error(
            "GV-RUNTIME-GITIGNORE-MISSING",
            "runtime",
            gitignore,
            ".gitignore is required for Goal runtime boundary enforcement",
            ".config/cache/ ignored and .config/goal/ tracked",
            None,
        )
        return

    active = active_gitignore_lines(gitignore)
    normalized = {line.lstrip("/") for _, line in active}

    if ".config/cache/" not in normalized:
        report.error(
            "GV-RUNTIME-CACHE-IGNORE",
            "runtime",
            gitignore,
            "runtime/cache output must live under .config/cache/",
            "active .gitignore line: .config/cache/",
            sorted(normalized),
        )

    if "!.config/goal/" not in normalized:
        report.error(
            "GV-RUNTIME-GOAL-UNIGNORE",
            "runtime",
            gitignore,
            "Goal control-plane files must remain trackable",
            "active .gitignore line: !.config/goal/",
            sorted(normalized),
        )

    old_runtime_roots = {
        ".config/goal/runtime/",
        ".config/goal/cache/",
        ".config/goal/logs/",
        ".config/goal/**/runtime/",
        ".config/goal/**/cache/",
        ".config/goal/**/logs/",
    }
    for line_number, line in active:
        normalized_line = line.lstrip("/")
        if normalized_line in old_runtime_roots:
            report.error(
                "GV-RUNTIME-OLD-ROOT",
                "runtime",
                path_at(gitignore, line_number),
                "old Goal runtime/cache/log roots must not be ignored under .config/goal/",
                ".config/cache/ is the only runtime/cache root",
                normalized_line,
            )


def check_matrix(root: Path, report: Report) -> None:
    matrix_path = root / ".config/goal/matrix/matrix.yaml"
    if not matrix_path.exists():
        report.error(
            "GV-MATRIX-MISSING",
            "matrix",
            matrix_path,
            "Traceability matrix is missing",
            str(matrix_path),
            None,
        )
        return

    rows = parse_matrix(matrix_path)
    if not rows:
        report.error(
            "GV-MATRIX-EMPTY",
            "matrix",
            matrix_path,
            "Traceability matrix has no rows",
            "at least one matrix edge",
            0,
        )
        return

    for index, row in enumerate(rows, start=1):
        row_path = path_at(matrix_path, row.get("_line"))
        keys = set(str(key) for key in row.get("_keys", []))

        legacy = sorted(keys & EDGE_LEGACY_FIELDS)
        if legacy:
            report.error(
                "GV-MATRIX-LEGACY-FIELD",
                "matrix",
                row_path,
                "matrix row uses legacy flat-traceability fields",
                ", ".join(EDGE_REQUIRED_FIELDS),
                legacy,
            )

        unknown = sorted(keys - EDGE_ALLOWED_FIELDS - EDGE_LEGACY_FIELDS)
        if unknown:
            report.error(
                "GV-MATRIX-UNKNOWN-FIELD",
                "matrix",
                row_path,
                "matrix row contains fields outside the canonical edge contract",
                ", ".join(sorted(EDGE_ALLOWED_FIELDS)),
                unknown,
            )

        missing = [field for field in EDGE_REQUIRED_FIELDS if field not in row]
        if missing:
            report.error(
                "GV-MATRIX-MISSING-FIELD",
                "matrix",
                row_path,
                f"matrix row {index} is missing canonical fields",
                ", ".join(EDGE_REQUIRED_FIELDS),
                missing,
            )

        empty = [
            field
            for field in EDGE_NON_EMPTY_FIELDS
            if field in row and not str(row.get(field, "")).strip()
        ]
        if empty:
            report.error(
                "GV-MATRIX-EMPTY-FIELD",
                "matrix",
                row_path,
                f"matrix row {index} has empty required fields",
                "non-empty source_id,target_id,relation,status,gate_id,owner,updated_at",
                empty,
            )

        relation = str(row.get("relation", ""))
        if relation and relation not in EDGE_RELATIONS:
            report.error(
                "GV-MATRIX-BAD-RELATION",
                "matrix",
                row_path,
                "matrix row has invalid relation",
                ", ".join(sorted(EDGE_RELATIONS)),
                relation,
            )

        status = str(row.get("status", ""))
        if status and status not in EDGE_STATUSES:
            report.error(
                "GV-MATRIX-BAD-STATUS",
                "matrix",
                row_path,
                "matrix row has invalid status",
                ", ".join(sorted(EDGE_STATUSES)),
                status,
            )

        if status == "Verified" and not str(row.get("evidence_id", "")).strip():
            report.error(
                "GV-MATRIX-VERIFIED-EVIDENCE",
                "matrix",
                row_path,
                "Verified matrix rows must carry a single evidence_id",
                "non-empty evidence_id",
                row.get("evidence_id"),
            )

        if status == "Dropped" and not str(row.get("drop_reason", "")).strip():
            report.error(
                "GV-MATRIX-DROPPED-REASON",
                "matrix",
                row_path,
                "Dropped matrix rows must explain why the edge was dropped",
                "non-empty drop_reason",
                row.get("drop_reason"),
            )


def gate_open_release_blocking_risks(gates: dict[str, dict[str, Any]]) -> dict[str, dict[str, Any]]:
    risks: dict[str, dict[str, Any]] = {}
    for gate in gates.values():
        risk = gate.get("risk") if isinstance(gate.get("risk"), dict) else {}
        if not risk:
            continue
        risk_id = str(risk.get("risk_id", "")).strip()
        if (
            risk_id
            and is_truthy(risk.get("release_blocking"))
            and normalize_status(risk.get("status")) in OPEN_STATUSES
        ):
            risks[risk_id] = {
                "risk_id": risk_id,
                "gate_id": gate.get("gate_id"),
                "gate_line": gate.get("_line"),
                **risk,
            }
    return risks


def registry_open_release_blocking_risks(risks: dict[str, dict[str, Any]]) -> dict[str, dict[str, Any]]:
    open_risks: dict[str, dict[str, Any]] = {}
    for risk_id, risk in risks.items():
        if is_truthy(risk.get("release_blocking")) and normalize_status(risk.get("status")) in OPEN_STATUSES:
            open_risks[risk_id] = risk
    return open_risks


def check_gate(root: Path, report: Report) -> None:
    gates_path = root / ".config/goal/gates/state.yaml"
    if not gates_path.exists():
        report.error(
            "GV-GATE-MISSING",
            "gate",
            gates_path,
            "Gate state file is missing",
            str(gates_path),
            None,
        )
        return

    gates = parse_gates(gates_path)
    duplicate_gates = find_duplicate_ids(gates_path, GATE_ID_EXTRACTORS)
    for gate_id, lines in sorted(duplicate_gates.items()):
        report.error(
            "GV-GATE-DUPLICATE-ID",
            "gate",
            path_at(gates_path, lines[0]),
            "Gate state contains duplicate gate_id entries",
            "one entry per canonical gate_id",
            {"gate_id": gate_id, "lines": lines},
        )

    found = set(gates)
    missing = [gate_id for gate_id in GATE_IDS if gate_id not in found]
    if missing:
        report.error(
            "GV-GATE-REQUIRED-MISSING",
            "gate",
            gates_path,
            "Gate state must include every canonical gate G0-G11",
            ", ".join(GATE_IDS),
            missing,
        )

    for gate_id, gate in gates.items():
        gate_path = path_at(gates_path, gate.get("_line"))
        status = normalize_status(gate.get("status"))
        verdict = normalize_status(gate.get("result", {}).get("verdict"))
        risk = gate.get("risk") if isinstance(gate.get("risk"), dict) else {}
        risk_id = str(risk.get("risk_id", "")).strip()

        if risk_id and not RISK_ID_PATTERN.fullmatch(risk_id):
            report.error(
                "GV-GATE-RISK-ID-FORMAT",
                "gate",
                gate_path,
                "gate risk metadata has invalid risk_id format",
                RISK_ID_EXPECTED,
                {"gate_id": gate_id, "risk_id": risk_id},
            )

        if status == "PENDING":
            report.error(
                "GV-GATE-PENDING-STATUS",
                "gate",
                gate_path,
                "PENDING is not a valid persisted gate status",
                ", ".join(sorted(GATE_TERMINAL_STATUSES)),
                status,
            )
        elif status and status not in GATE_TERMINAL_STATUSES:
            report.error(
                "GV-GATE-BAD-STATUS",
                "gate",
                gate_path,
                "Gate has invalid status",
                ", ".join(sorted(GATE_TERMINAL_STATUSES)),
                status,
            )

        if verdict == "PENDING":
            report.error(
                "GV-GATE-PENDING-VERDICT",
                "gate",
                gate_path,
                "PENDING is not a valid persisted result verdict",
                ", ".join(sorted(GATE_TERMINAL_STATUSES)),
                verdict,
            )
        elif verdict and verdict not in GATE_TERMINAL_STATUSES:
            report.error(
                "GV-GATE-BAD-VERDICT",
                "gate",
                gate_path,
                "Gate result verdict is invalid",
                ", ".join(sorted(GATE_TERMINAL_STATUSES)),
                verdict,
            )

        if status and verdict and status != verdict:
            report.error(
                "GV-GATE-STATUS-VERDICT-MISMATCH",
                "gate",
                gate_path,
                "Gate status and result.verdict must describe the same decision",
                "status == result.verdict",
                {"status": status, "result.verdict": verdict},
            )

        if gate_id in PASS_WITH_RISK_DISALLOWED and (
            status == "PASS_WITH_RISK" or verdict == "PASS_WITH_RISK"
        ):
            report.error(
                "GV-GATE-PASS-WITH-RISK-DISALLOWED",
                "gate",
                gate_path,
                f"{gate_id} must block or fail instead of PASS_WITH_RISK",
                "FAIL or BLOCKED when unresolved risk remains",
                {"status": status, "result.verdict": verdict},
            )

        if status == "PASS_WITH_RISK" or verdict == "PASS_WITH_RISK":
            if not is_truthy(gate.get("allow_pass_with_risk")):
                report.error(
                    "GV-GATE-PASS-WITH-RISK-NOT-ALLOWED",
                    "gate",
                    gate_path,
                    "PASS_WITH_RISK requires allow_pass_with_risk: true",
                    "allow_pass_with_risk: true",
                    gate.get("allow_pass_with_risk"),
                )

            missing_risk = sorted(field for field in PASS_WITH_RISK_REQUIRED if not risk.get(field))
            if not any(risk.get(field) for field in PASS_WITH_RISK_OWNER_FIELDS):
                missing_risk.append("risk_owner|owner")
            if missing_risk:
                report.error(
                    "GV-GATE-PASS-WITH-RISK-METADATA",
                    "gate",
                    gate_path,
                    "PASS_WITH_RISK must carry auditable risk metadata",
                    "risk_id, risk_owner|owner, mitigation, due_at, release_blocking, status",
                    missing_risk,
                )


def check_risk(root: Path, report: Report) -> None:
    gates_path = root / ".config/goal/gates/state.yaml"
    risks_path = root / ".config/goal/registry/risks.yaml"
    gates = parse_gates(gates_path)
    gate_risks = gate_open_release_blocking_risks(gates)

    if not risks_path.exists():
        if gate_risks:
            report.error(
                "GV-RISK-REGISTRY-MISSING",
                "risk",
                risks_path,
                "open release_blocking gate risks must be tracked in the Risk Registry",
                "registry entries for every open release_blocking gate risk",
                sorted(gate_risks),
            )
        return

    risks = parse_risks(risks_path)
    duplicate_risks = find_duplicate_ids(risks_path, RISK_ID_EXTRACTORS)
    for risk_id, lines in sorted(duplicate_risks.items()):
        report.error(
            "GV-RISK-DUPLICATE-ID",
            "risk",
            path_at(risks_path, lines[0]),
            "Risk Registry contains duplicate risk_id entries",
            "one registry entry per risk_id",
            {"risk_id": risk_id, "lines": lines},
        )

    for risk_id, risk in risks.items():
        if not RISK_ID_PATTERN.fullmatch(risk_id):
            report.error(
                "GV-RISK-ID-FORMAT",
                "risk",
                path_at(risks_path, risk.get("_line")),
                "Risk Registry entry has invalid risk_id format",
                RISK_ID_EXPECTED,
                risk_id,
            )

    missing = sorted(risk_id for risk_id in gate_risks if risk_id not in risks)
    if missing:
        report.error(
            "GV-RISK-GATE-REGISTRY-DRIFT",
            "risk",
            risks_path,
            "open release_blocking gate risks are missing from the Risk Registry",
            "matching risk_id entries in .config/goal/registry/risks.yaml",
            missing,
        )


def check_workflow_stale_contract(root: Path, report: Report) -> None:
    workflow = root / ".github/workflows/goal-ci.yml"
    if not workflow.exists():
        return

    stale_literals = {
        "requirement_id": "source_id/target_id",
        "evidence_ids": "evidence_id",
        "PENDING": "PASS|PASS_WITH_RISK|FAIL|BLOCKED",
    }
    active_lines: list[str] = []
    for line_number, raw_line in enumerate(read_lines(workflow), start=1):
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        active_lines.append(raw_line)
        for stale, expected in stale_literals.items():
            if stale in raw_line:
                report.error(
                    "GV-CONSISTENCY-CI-STALE-CONTRACT",
                    "consistency",
                    path_at(workflow, line_number),
                    "GitHub workflow contains stale Goal validation vocabulary",
                    expected,
                    stale,
                )

        result_verdicts = re.search(r"valid_result_verdicts\s*=\s*\[(.*?)\]", raw_line)
        if result_verdicts and "BLOCKED" not in result_verdicts.group(1):
            report.error(
                "GV-CONSISTENCY-CI-MISSING-BLOCKED",
                "consistency",
                path_at(workflow, line_number),
                "GitHub workflow result verdict enum must include BLOCKED",
                "PASS, PASS_WITH_RISK, FAIL, BLOCKED",
                result_verdicts.group(0),
            )

    active_text = "\n".join(active_lines)
    job_ids = set(re.findall(r"^  ([A-Za-z0-9_-]+):\s*$", workflow.read_text(encoding="utf-8"), re.MULTILINE))
    if "goal-validator" not in job_ids:
        report.error(
            "GV-CONSISTENCY-CI-MISSING-GOAL-VALIDATOR",
            "consistency",
            workflow,
            "GitHub workflow must define goal-validator as the independent strict validator job",
            "jobs.goal-validator",
            sorted(job_ids),
        )

    if "docs/goal/tools/goal-validate.py" not in active_text or "--mode strict" not in active_text:
        report.error(
            "GV-CONSISTENCY-CI-MISSING-GOAL-VALIDATOR",
            "consistency",
            workflow,
            "GitHub workflow must run the Goal control-plane validator in strict mode",
            "python3 docs/goal/tools/goal-validate.py --root . --mode strict",
            "<missing>",
        )

    rules = root / ".config/goal/schema/rules.yaml"
    required_jobs = parse_ci_required_jobs(rules)
    if rules.exists() and "goal-validator" not in required_jobs:
        report.error(
            "GV-CONSISTENCY-CI-MISSING-GOAL-VALIDATOR",
            "consistency",
            rules,
            "rules.yaml ci.required_jobs must require the strict Goal validator job",
            "ci.required_jobs includes goal-validator",
            sorted(required_jobs),
        )


def check_consistency(root: Path, report: Report) -> None:
    gates_path = root / ".config/goal/gates/state.yaml"
    risks_path = root / ".config/goal/registry/risks.yaml"
    pipeline_path = root / ".config/goal/pipeline/state.yaml"
    releases_path = root / ".config/goal/registry/releases.yaml"

    gates = parse_gates(gates_path)
    registry_risks = parse_risks(risks_path)
    open_gate_risks = gate_open_release_blocking_risks(gates)
    open_registry_risks = registry_open_release_blocking_risks(registry_risks)
    open_release_blocking_risks = {**open_registry_risks, **open_gate_risks}

    g10_status = normalize_status(gates.get("G10", {}).get("status"))
    g11_status = normalize_status(gates.get("G11", {}).get("status"))

    if open_release_blocking_risks and g10_status != "BLOCKED":
        report.error(
            "GV-CONSISTENCY-G10-OPEN-RISK",
            "consistency",
            path_at(gates_path, gates.get("G10", {}).get("_line")),
            "open release_blocking risks must block G10",
            "G10 status/result.verdict: BLOCKED",
            g10_status,
        )

    if g10_status and g10_status != "PASS" and g11_status == "PASS":
        report.error(
            "GV-CONSISTENCY-G11-AFTER-G10",
            "consistency",
            path_at(gates_path, gates.get("G11", {}).get("_line")),
            "G11 cannot PASS while G10 is not PASS",
            "G11 BLOCKED/FAIL until G10 PASS",
            {"G10": g10_status, "G11": g11_status},
        )

    if open_release_blocking_risks:
        pipeline = parse_pipeline(pipeline_path)
        pipeline_state = normalize_status(pipeline.get("pipeline_state"))
        if pipeline_state in DONE_PIPELINE_STATES:
            report.error(
                "GV-CONSISTENCY-PIPELINE-DONE-WITH-RISK",
                "consistency",
                path_at(pipeline_path, pipeline.get("_line")),
                "pipeline cannot be DONE with open release_blocking risks",
                "pipeline_state: BLOCKED or an active review/remediation state",
                pipeline_state,
            )

        for release in parse_releases(releases_path):
            release_status = normalize_status(release.get("status"))
            if release_status in RELEASED_STATUSES:
                report.error(
                    "GV-CONSISTENCY-RELEASED-WITH-RISK",
                    "consistency",
                    path_at(releases_path, release.get("_line")),
                    "release cannot be marked released with open release_blocking risks",
                    "status: in_review, rejected, or draft until risks are closed",
                    {"release_id": release.get("release_id"), "status": release.get("status")},
                )

    check_workflow_stale_contract(root, report)


CHECKS = {
    "runtime": check_runtime,
    "matrix": check_matrix,
    "gate": check_gate,
    "risk": check_risk,
    "consistency": check_consistency,
}


def parse_only(raw: str | None) -> list[str]:
    if not raw:
        return list(AREAS)
    selected = [item.strip() for item in raw.split(",") if item.strip()]
    unknown = [item for item in selected if item not in AREAS]
    if unknown:
        raise ValueError(f"unknown --only area(s): {', '.join(unknown)}")
    return selected


def emit_text(report: Report, mode: str) -> None:
    if not report.violations:
        print(f"goal validation passed ({mode})")
        return

    print(
        f"goal validation found {report.error_count} error(s), "
        f"{report.warn_count} warning(s) ({mode})"
    )
    for item in report.violations:
        suffix = f"expected: {item.expected}; actual: {item.actual}"
        print(f"[{item.severity}] {item.id} {item.area} {item.path}: {item.message} ({suffix})")


def emit_json(report: Report, mode: str) -> None:
    payload = {
        "mode": mode,
        "status": "pass" if report.error_count == 0 else "blocked",
        "error_count": report.error_count,
        "warn_count": report.warn_count,
        "violations": [asdict(item) for item in report.violations],
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Validate Goal control-plane bootstrap invariants")
    parser.add_argument("--root", default=".", help="repository root to validate")
    parser.add_argument("--mode", choices=("audit", "strict"), default="audit")
    parser.add_argument("--format", choices=("text", "json"), default="text")
    parser.add_argument(
        "--only",
        help="comma-separated validation areas: runtime,matrix,gate,risk,consistency",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    root = Path(args.root).resolve()

    try:
        selected = parse_only(args.only)
    except ValueError as exc:
        parser.error(str(exc))

    report = Report()
    for area in selected:
        CHECKS[area](root, report)

    if args.format == "json":
        emit_json(report, args.mode)
    else:
        emit_text(report, args.mode)

    if args.mode == "strict" and report.error_count:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
