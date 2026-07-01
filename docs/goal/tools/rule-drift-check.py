#!/usr/bin/env python3
"""Executable drift checker for the Goal rule single source of truth.

The checker intentionally uses only the Python standard library so it can run
inside CI before any project dependencies are installed.
"""

from __future__ import annotations

import argparse
import fnmatch
import re
import sys
from pathlib import Path
from typing import Any


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


def parse_int(value: str) -> int | str:
    return int(value) if value.isdigit() else value


def parse_inline_list(value: str) -> list[str]:
    value = clean_value(value)
    if value.startswith("[") and value.endswith("]"):
        inner = value[1:-1].strip()
        if not inner:
            return []
        return [clean_value(part) for part in inner.split(",") if clean_value(part)]
    return [value] if value else []


def as_list(value: Any) -> list[str]:
    if isinstance(value, list):
        return [str(item) for item in value]
    if isinstance(value, str):
        return parse_inline_list(value)
    return []


def is_true(value: Any) -> bool:
    return value is True or str(value).strip().lower() in {"true", "yes", "1"}


EDGE_REQUIRED_FIELDS = {
    "source_id",
    "target_id",
    "relation",
    "status",
    "evidence_id",
    "gate_id",
    "owner",
    "updated_at",
}
EDGE_NON_EMPTY_FIELDS = EDGE_REQUIRED_FIELDS - {"evidence_id"}
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
EDGE_TERMINAL_STATUSES = {"Verified", "Dropped"}
GATE_DECISION_STATUSES = {"PASS", "PASS_WITH_RISK", "FAIL", "BLOCKED"}
GATE_LIFECYCLE_STATUSES = GATE_DECISION_STATUSES | {"NOT_STARTED", "IN_PROGRESS"}
MATRIX_TERMINAL_COVERAGE_THRESHOLD = 95
MATRIX_WARNING_COVERAGE_THRESHOLD = 60
LEGACY_NAMESPACE_MODE = "grandfathered_import_only"
MODULE_CODE_ROOT_PATTERN = "/home/workspace/{module}"
MODULE_SPEC_ROOT_PATTERN = "module/{module}/"
MODULE_REPOSITORY_BOUNDARY = "ZoneCNH/ZoneCNH"
MODULE_REQUIRED_LINT_RULES = {"C-LINT-006", "C-LINT-007"}
MODULE_STALE_PATH_PLACEHOLDERS = {
    "/home/<module>",
    "module/<module>",
}
MODULE_STALE_TREE_PLACEHOLDER = re.compile(r"^\s+<module>/", re.MULTILINE)
MODULE_FORBIDDEN_SOURCE_PATTERNS = {
    "module/{module}/cmd/",
    "module/{module}/internal/",
    "module/{module}/pkg/",
    "module/{module}/vendor/",
    "module/{module}/go.mod",
    "module/{module}/go.sum",
}
MODULE_SOURCE_FILE_SUFFIXES = {
    ".c",
    ".cc",
    ".cpp",
    ".cs",
    ".go",
    ".h",
    ".hpp",
    ".java",
    ".js",
    ".jsx",
    ".kt",
    ".php",
    ".py",
    ".rb",
    ".rs",
    ".swift",
    ".ts",
    ".tsx",
}
MODULE_SOURCE_CONFIG_FILES = {
    "Cargo.toml",
    "Dockerfile",
    "Makefile",
    "build.gradle",
    "go.mod",
    "go.sum",
    "package.json",
    "pom.xml",
    "pyproject.toml",
}


def load_rules(path: Path) -> dict[str, dict[str, Any]]:
    rules: dict[str, dict[str, Any]] = {}
    section: str | None = None
    key: str | None = None

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue

        top = re.match(r"^([A-Za-z_]+):(?:\s*(.*))?$", raw_line)
        if top:
            name, value = top.group(1), clean_value(top.group(2) or "")
            if value:
                rules[name] = {"value": parse_int(value)}
                section = None
                key = None
            else:
                rules.setdefault(name, {})
                section = name
                key = None
            continue

        child = re.match(r"^  ([A-Za-z_]+):(?:\s*(.*))?$", raw_line)
        if child and section:
            key, value = child.group(1), clean_value(child.group(2) or "")
            rules[section][key] = parse_int(value) if value else []
            continue

        nested = re.match(r"^    ([A-Za-z_]+):(?:\s*(.*))?$", raw_line)
        if nested and section and key:
            if not isinstance(rules[section].get(key), dict):
                rules[section][key] = {}
            name, value = nested.group(1), clean_value(nested.group(2) or "")
            rules[section][key][name] = parse_int(value) if value else {}
            continue

        item = re.match(r"^    -\s*(.+?)\s*$", raw_line)
        if item and section and key:
            rules[section].setdefault(key, [])
            if not isinstance(rules[section][key], list):
                rules[section][key] = []
            rules[section][key].append(clean_value(item.group(1)))

    return rules


class Report:
    def __init__(self, quiet: bool) -> None:
        self.quiet = quiet
        self.failures: list[str] = []

    def pass_(self, message: str) -> None:
        if not self.quiet:
            print(f"[PASS] {message}")

    def fail(self, message: str) -> None:
        self.failures.append(message)
        if not self.quiet:
            print(f"[FAIL] {message}")


def check_schema_rules(rules: dict[str, dict[str, Any]], report: Report) -> None:
    ok = True

    def fail(message: str) -> None:
        nonlocal ok
        ok = False
        report.fail(message)

    matrix = rules.get("matrix", {})
    if matrix.get("coverage_threshold") != MATRIX_TERMINAL_COVERAGE_THRESHOLD:
        fail(
            "rules.yaml matrix.coverage_threshold drift: "
            f"expected {MATRIX_TERMINAL_COVERAGE_THRESHOLD}, actual {matrix.get('coverage_threshold')}"
        )
    if matrix.get("terminal_coverage_threshold") != MATRIX_TERMINAL_COVERAGE_THRESHOLD:
        fail(
            "rules.yaml matrix.terminal_coverage_threshold drift: "
            f"expected {MATRIX_TERMINAL_COVERAGE_THRESHOLD}, "
            f"actual {matrix.get('terminal_coverage_threshold')}"
        )
    if matrix.get("warning_coverage_threshold") != MATRIX_WARNING_COVERAGE_THRESHOLD:
        fail(
            "rules.yaml matrix.warning_coverage_threshold drift: "
            f"expected {MATRIX_WARNING_COVERAGE_THRESHOLD}, "
            f"actual {matrix.get('warning_coverage_threshold')}"
        )

    gate = rules.get("gate", {})
    status_values = set(as_list(gate.get("status_values", [])))
    lifecycle_status_values = set(as_list(gate.get("lifecycle_status_values", [])))
    result_verdicts = set(as_list(gate.get("result_verdicts", [])))
    if status_values != GATE_LIFECYCLE_STATUSES:
        fail(
            "rules.yaml gate.status_values drift: "
            f"expected {sorted(GATE_LIFECYCLE_STATUSES)}, actual {sorted(status_values)}"
        )
    if lifecycle_status_values != GATE_LIFECYCLE_STATUSES:
        fail(
            "rules.yaml gate.lifecycle_status_values drift: "
            f"expected {sorted(GATE_LIFECYCLE_STATUSES)}, actual {sorted(lifecycle_status_values)}"
        )
    if result_verdicts != GATE_DECISION_STATUSES:
        fail(
            "rules.yaml gate.result_verdicts drift: "
            f"expected {sorted(GATE_DECISION_STATUSES)}, actual {sorted(result_verdicts)}"
        )
    if "PENDING" in status_values or "PENDING" in lifecycle_status_values or "PENDING" in result_verdicts:
        fail("rules.yaml gate vocabularies must not contain PENDING")
    if {"NOT_STARTED", "IN_PROGRESS"} & result_verdicts:
        fail("rules.yaml gate.result_verdicts must not contain lifecycle-only statuses")

    ids = rules.get("ids", {})
    if str(ids.get("legacy_namespace_mode")) != LEGACY_NAMESPACE_MODE:
        fail(
            "rules.yaml ids.legacy_namespace_mode drift: "
            f"expected {LEGACY_NAMESPACE_MODE}, actual {ids.get('legacy_namespace_mode')}"
        )
    if str(ids.get("legacy_namespace_allowed")) != "XLIB":
        fail(
            "rules.yaml ids.legacy_namespace_allowed drift: "
            f"expected XLIB, actual {ids.get('legacy_namespace_allowed')}"
        )
    if not is_true(ids.get("legacy_parse_only")):
        fail("rules.yaml ids.legacy_parse_only must be true")
    if not is_true(ids.get("canonical_output_required")):
        fail("rules.yaml ids.canonical_output_required must be true")

    evidence = rules.get("evidence", {})
    if str(evidence.get("legacy_namespace_mode")) != LEGACY_NAMESPACE_MODE:
        fail(
            "rules.yaml evidence.legacy_namespace_mode drift: "
            f"expected {LEGACY_NAMESPACE_MODE}, actual {evidence.get('legacy_namespace_mode')}"
        )

    if ok:
        report.pass_("Schema rule invariants match executable Goal policy")


def matches_module_artifact(path: Path, allowed_patterns: list[str]) -> bool:
    name = f"{path.name}/" if path.is_dir() else path.name
    return any(fnmatch.fnmatchcase(name, pattern) for pattern in allowed_patterns)


def is_module_source_file(path: Path) -> bool:
    return path.name in MODULE_SOURCE_CONFIG_FILES or path.suffix in MODULE_SOURCE_FILE_SUFFIXES


def sample_paths(paths: list[str], limit: int = 10) -> str:
    if len(paths) <= limit:
        return ", ".join(paths)
    return ", ".join(paths[:limit]) + f", ... (+{len(paths) - limit} more)"


def check_module_code_location(
    root: Path,
    rules: dict[str, dict[str, Any]],
    report: Report,
) -> None:
    ok = True

    def fail(message: str) -> None:
        nonlocal ok
        ok = False
        report.fail(message)

    policy = rules.get("module_code_location", {})
    canonical_path = str(policy.get("canonical_path_pattern", ""))
    spec_root = str(policy.get("specification_artifact_root_pattern", ""))
    if canonical_path != MODULE_CODE_ROOT_PATTERN:
        fail(
            "module_code_location.canonical_path_pattern drift: "
            f"expected {MODULE_CODE_ROOT_PATTERN}, actual {canonical_path}"
        )
    if spec_root != MODULE_SPEC_ROOT_PATTERN:
        fail(
            "module_code_location.specification_artifact_root_pattern drift: "
            f"expected {MODULE_SPEC_ROOT_PATTERN}, actual {spec_root}"
        )
    if str(policy.get("repository_boundary", "")) != MODULE_REPOSITORY_BOUNDARY:
        fail(
            "module_code_location.repository_boundary drift: "
            f"expected {MODULE_REPOSITORY_BOUNDARY}, actual {policy.get('repository_boundary')}"
        )
    if str(policy.get("prompt_required_code_root", "")) != MODULE_CODE_ROOT_PATTERN:
        fail("module_code_location.prompt_required_code_root must be /home/workspace/{module}")
    if str(policy.get("evidence_allowed_changed_file_prefix", "")) != f"{MODULE_CODE_ROOT_PATTERN}/":
        fail("module_code_location.evidence_allowed_changed_file_prefix must be /home/workspace/{module}/")
    if str(policy.get("forbidden_copy_source_pattern", "")) != f"{MODULE_CODE_ROOT_PATTERN}/**":
        fail("module_code_location.forbidden_copy_source_pattern must be /home/workspace/{module}/**")

    forbidden_patterns = set(as_list(policy.get("forbidden_repository_patterns", [])))
    missing_forbidden = sorted(MODULE_FORBIDDEN_SOURCE_PATTERNS - forbidden_patterns)
    if missing_forbidden:
        fail("module_code_location missing forbidden source patterns: " + ", ".join(missing_forbidden))

    lint_rules = set(as_list(policy.get("lint_rules", [])))
    missing_lint_rules = sorted(MODULE_REQUIRED_LINT_RULES - lint_rules)
    if missing_lint_rules:
        fail("module_code_location missing lint rules: " + ", ".join(missing_lint_rules))

    lint_doc = root / "docs/goal/10-lint-rules.md"
    if lint_doc.exists():
        lint_text = lint_doc.read_text(encoding="utf-8")
        missing_lint_doc = sorted(rule for rule in MODULE_REQUIRED_LINT_RULES if rule not in lint_text)
        if missing_lint_doc:
            fail("docs/goal/10-lint-rules.md missing lint rules: " + ", ".join(missing_lint_doc))
    else:
        fail(f"Lint rule document missing: {lint_doc}")

    allowed_artifacts = as_list(policy.get("allowed_module_artifacts", []))
    if not allowed_artifacts:
        fail("module_code_location.allowed_module_artifacts is empty")

    module_root = root / "module"
    if not module_root.exists():
        fail(f"Module artifact root missing: {module_root}")
        return

    module_dirs = sorted(path for path in module_root.iterdir() if path.is_dir())
    expected_count = rules.get("module_goal_document", {}).get("module_count")
    if isinstance(expected_count, int) and len(module_dirs) != expected_count:
        fail(
            "module_goal_document.module_count drift: "
            f"expected {expected_count}, actual {len(module_dirs)}"
        )

    unexpected_artifacts: list[str] = []
    forbidden_hits: list[str] = []
    source_hits: list[str] = []
    stale_path_hits: list[str] = []

    for module_dir in module_dirs:
        for child in sorted(module_dir.iterdir()):
            if not matches_module_artifact(child, allowed_artifacts):
                unexpected_artifacts.append(str(child.relative_to(root)))

        for pattern in forbidden_patterns:
            candidate = root / pattern.replace("{module}", module_dir.name)
            if candidate.exists():
                forbidden_hits.append(str(candidate.relative_to(root)))

        for path in sorted(module_dir.rglob("*")):
            if path.is_file() and is_module_source_file(path):
                source_hits.append(str(path.relative_to(root)))

    for path in sorted(module_root.iterdir()):
        if path.is_file() and is_module_source_file(path):
            source_hits.append(str(path.relative_to(root)))

    placeholder_targets = [
        root / "AGENTS.md",
        root / "ARCHITECTURE.md",
        root / "CONSTITUTION.md",
        root / "docs/goal",
        root / "module",
    ]
    for target in placeholder_targets:
        paths = [target] if target.is_file() else sorted(target.rglob("*.md")) if target.exists() else []
        for path in paths:
            text = path.read_text(encoding="utf-8")
            for number, line in enumerate(text.splitlines(), start=1):
                if any(marker in line for marker in MODULE_STALE_PATH_PLACEHOLDERS):
                    stale_path_hits.append(f"{path.relative_to(root)}:{number}")
                elif MODULE_STALE_TREE_PLACEHOLDER.search(line):
                    stale_path_hits.append(f"{path.relative_to(root)}:{number}")

    if unexpected_artifacts:
        fail("module/ contains paths outside allowed Goal artifacts: " + sample_paths(unexpected_artifacts))
    if forbidden_hits:
        fail("module/ contains forbidden module source paths: " + sample_paths(forbidden_hits))
    if source_hits:
        fail("module/ contains source-like module implementation files: " + sample_paths(source_hits))
    if stale_path_hits:
        fail(
            "module code path placeholders must use {module}, not <module>: "
            + sample_paths(stale_path_hits)
        )

    if ok:
        report.pass_(
            f"Module code location policy keeps {len(module_dirs)} module specs outside /home/workspace/{{module}} code roots"
        )


def parse_matrix(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None
    current_key: str | None = None

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        start = re.match(r"^\s*-\s+(source_id|goal_id):\s*(.*)$", raw_line)
        if start:
            if current:
                rows.append(current)
            current = {"source_id": clean_value(start.group(2))}
            current_key = "source_id"
            continue

        if current is None:
            continue

        field = re.match(r"^\s+([A-Za-z_]+):\s*(.*)$", raw_line)
        if field:
            current_key = field.group(1)
            value = clean_value(field.group(2))
            current[current_key] = parse_inline_list(value) if value.startswith("[") else value
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


def check_registry(root: Path, rules: dict[str, dict[str, Any]], report: Report) -> None:
    registry_dir = root / str(rules["registry"]["directory"])
    expected = set(as_list(rules["registry"]["files"]))
    actual = {path.name for path in registry_dir.glob("*.yaml")} if registry_dir.exists() else set()

    if not registry_dir.exists():
        report.fail(f"Registry directory missing: {registry_dir}")
    elif actual == expected:
        report.pass_("Registry file set matches rules.yaml")
    else:
        report.fail(f"Registry file set drift: expected {sorted(expected)}, actual {sorted(actual)}")


def check_matrix(root: Path, rules: dict[str, dict[str, Any]], report: Report) -> set[str]:
    matrix_file = root / str(rules["matrix"]["file"])
    if not matrix_file.exists():
        report.fail(f"Matrix file missing: {matrix_file}")
        return set()

    rows = parse_matrix(matrix_file)
    configured_required = set(as_list(rules["matrix"].get("required_fields", [])))
    allowed_statuses = set(as_list(rules["matrix"].get("statuses", []))) or EDGE_STATUSES
    terminal_statuses = (
        set(as_list(rules["matrix"].get("terminal_statuses", []))) or EDGE_TERMINAL_STATUSES
    )
    allowed_relations = set(as_list(rules["matrix"].get("relations", []))) or EDGE_RELATIONS
    threshold = int(
        rules["matrix"].get(
            "terminal_coverage_threshold",
            rules["matrix"].get("coverage_threshold", MATRIX_TERMINAL_COVERAGE_THRESHOLD),
        )
    )

    if configured_required and configured_required != EDGE_REQUIRED_FIELDS:
        report.fail(
            "rules.yaml matrix.required_fields drift: "
            f"expected {sorted(EDGE_REQUIRED_FIELDS)}, actual {sorted(configured_required)}"
        )

    if not rows:
        report.fail("Matrix has no edges")
        return set()

    evidence_refs: set[str] = set()
    terminal = 0
    for index, row in enumerate(rows, start=1):
        missing = sorted(field for field in EDGE_REQUIRED_FIELDS if field not in row)
        if missing:
            report.fail(f"Matrix edge {index} missing fields: {', '.join(missing)}")

        empty = sorted(
            field
            for field in EDGE_NON_EMPTY_FIELDS
            if field in row and not str(row.get(field, "")).strip()
        )
        if empty:
            report.fail(f"Matrix edge {index} has empty fields: {', '.join(empty)}")

        status = str(row.get("status", ""))
        relation = str(row.get("relation", ""))
        if relation not in allowed_relations:
            report.fail(f"Matrix edge {index} has invalid relation: {relation}")
        if status not in allowed_statuses:
            report.fail(f"Matrix edge {index} has invalid status: {status}")
        if status in terminal_statuses:
            terminal += 1

        evidence_ids = [ref for ref in as_list(row.get("evidence_id", "")) if ref]
        if status == "Verified" and not evidence_ids:
            report.fail(f"Matrix edge {index} is Verified but has no evidence_id")
        if status == "Dropped" and not row.get("drop_reason"):
            report.fail(f"Matrix edge {index} is Dropped but has no drop_reason")
        evidence_refs.update(evidence_ids)

    coverage = terminal * 100 // len(rows)
    if coverage < threshold:
        report.fail(f"Matrix edge terminal coverage {coverage}% is below {threshold}%")
    else:
        report.pass_(f"Matrix edge terminal coverage {coverage}% meets threshold {threshold}%")

    return evidence_refs


def parse_evidence_fields(path: Path) -> dict[str, str]:
    fields: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.match(r"^- \*\*(.+?)\*\*:\s*(.*)$", line)
        if match:
            fields[match.group(1)] = match.group(2).strip()
    return fields


def check_evidence(
    root: Path,
    rules: dict[str, dict[str, Any]],
    matrix_refs: set[str],
    report: Report,
) -> None:
    evidence_dir = root / str(rules["evidence"]["directory"])
    required = set(as_list(rules["evidence"]["required_fields"]))
    statuses = set(as_list(rules["evidence"]["statuses"]))
    id_pattern = re.compile(str(rules["evidence"]["id_pattern"]))
    task_pattern = re.compile(str(rules["evidence"]["task_id_pattern"]))

    if not evidence_dir.exists():
        report.fail(f"Evidence directory missing: {evidence_dir}")
        return

    files = sorted(evidence_dir.glob("**/EVID-*.md"))
    found: set[str] = set()
    for path in files:
        fields = parse_evidence_fields(path)
        evid = fields.get("Evidence ID", "")
        task = fields.get("Task ID", "")
        found.add(evid)

        rel_parts = path.relative_to(evidence_dir).parts
        if len(rel_parts) != 3:
            report.fail(f"Evidence path is not DATE/TASK_ID/EVID_ID.md: {path}")
        else:
            date_part, task_part, file_part = rel_parts
            if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", date_part):
                report.fail(f"Evidence date directory invalid: {path}")
            if not task_pattern.fullmatch(task_part):
                report.fail(f"Evidence task directory invalid: {path}")
            if file_part != f"{evid}.md":
                report.fail(f"Evidence filename does not match Evidence ID: {path}")
            if task and task != task_part:
                report.fail(f"Evidence Task ID does not match parent directory: {path}")

        missing = sorted(field for field in required if not fields.get(field))
        if missing:
            report.fail(f"Evidence {path} missing fields: {', '.join(missing)}")
        if evid and not id_pattern.fullmatch(evid):
            report.fail(f"Evidence ID format invalid: {evid}")
        if task and not task_pattern.fullmatch(task):
            report.fail(f"Evidence Task ID format invalid: {task}")
        if fields.get("Status") not in statuses:
            report.fail(f"Evidence status invalid in {path}: {fields.get('Status')}")

    missing_refs = sorted(ref for ref in matrix_refs if ref not in found)
    orphan_files = sorted(evid for evid in found if evid and evid not in matrix_refs)
    if missing_refs:
        report.fail(f"Matrix evidence references missing files: {', '.join(missing_refs)}")
    if orphan_files:
        report.fail(f"Evidence files not referenced by Matrix: {', '.join(orphan_files)}")
    if files and not missing_refs and not orphan_files:
        report.pass_(f"Evidence closure verified for {len(files)} files")


def parse_gates(path: Path) -> dict[str, dict[str, str]]:
    gates: dict[str, dict[str, str]] = {}
    current: str | None = None
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        start = re.match(r"^\s*-\s+gate_id:\s*([A-Z][A-Z0-9-]*)\s*$", raw_line)
        if start:
            gate_id = start.group(1)
            current = gate_id if re.fullmatch(r"G[0-9]+", gate_id) else None
            if current:
                gates[current] = {}
            continue
        if not current:
            continue
        # Gate-level status at 2-space indent (under "- gate_id:")
        status = re.match(r"^  status:\s*([A-Z_]+)\s*$", raw_line)
        if status:
            gates[current]["status"] = status.group(1)
        # Result verdict at 4-space indent (under "  result:")
        verdict = re.match(r"^    verdict:\s*([A-Z_]+)\s*$", raw_line)
        if verdict:
            gates[current]["verdict"] = verdict.group(1)
    return gates


def check_gates(root: Path, rules: dict[str, dict[str, Any]], report: Report) -> None:
    gate_file = root / str(rules["gate"]["file"])
    if not gate_file.exists():
        report.fail(f"Gate file missing: {gate_file}")
        return

    gates = parse_gates(gate_file)
    required_ids = set(as_list(rules["gate"]["ids"]))
    allowed_status = set(as_list(rules["gate"].get("lifecycle_status_values", []))) or set(
        as_list(rules["gate"]["status_values"])
    )
    allowed_verdict = set(as_list(rules["gate"]["result_verdicts"]))

    missing = sorted(required_ids - set(gates))
    if missing:
        report.fail(f"Gate IDs missing: {', '.join(missing)}")

    for gate_id, values in gates.items():
        status = values.get("status")
        verdict = values.get("verdict")
        if status not in allowed_status:
            report.fail(f"{gate_id} status invalid: {status}")
        if status not in allowed_verdict:
            report.fail(f"{gate_id} canonical status is not a decision status: {status}")
        if not verdict:
            report.fail(f"{gate_id} result.verdict missing")
        elif verdict not in allowed_verdict:
            report.fail(f"{gate_id} verdict invalid: {verdict}")
        elif status in allowed_verdict and status != verdict:
            report.fail(f"{gate_id} status/verdict mismatch: status={status}, verdict={verdict}")

    if not missing:
        report.pass_("Gate IDs and status vocabularies match rules.yaml")


def check_pipeline(root: Path, rules: dict[str, dict[str, Any]], report: Report) -> None:
    pipeline_file = root / str(rules["pipeline"]["file"])
    if not pipeline_file.exists():
        report.fail(f"Pipeline file missing: {pipeline_file}")
        return

    pipeline_rules = rules["pipeline"]
    states = set(as_list(pipeline_rules["states"]))
    phases = set(as_list(pipeline_rules["phases"]))
    phase_statuses = set(as_list(pipeline_rules["phase_statuses"]))
    state_axes = pipeline_rules.get("state_axes", {})
    workflow_steps = set(as_list(pipeline_rules.get("workflow_steps", [])))
    text = pipeline_file.read_text(encoding="utf-8")

    axis_ok = True
    expected_axes = {"pipeline_state", "current_phase", "phase_status", "workflow_step"}
    if not isinstance(state_axes, dict) or set(state_axes) != expected_axes:
        axis_ok = False
        actual_axes = sorted(state_axes) if isinstance(state_axes, dict) else state_axes
        report.fail(f"pipeline.state_axes mismatch: expected {sorted(expected_axes)}, actual {actual_axes}")
    if not workflow_steps:
        axis_ok = False
        report.fail("pipeline.workflow_steps enum is empty")

    invalid: list[str] = []
    seen_workflow_step = False
    value_pattern = (
        r"^\s*(pipeline_state|previous_pipeline_state|current_phase|phase_status|workflow_step):"
        r"\s*([A-Za-z0-9_-]+)\s*(?:#.*)?$"
    )
    for field, value in re.findall(value_pattern, text, re.MULTILINE):
        if field in {"pipeline_state", "previous_pipeline_state"} and value not in states:
            invalid.append(f"{field}={value}")
        elif field == "current_phase" and value not in phases:
            invalid.append(f"{field}={value}")
        elif field == "phase_status" and value not in phase_statuses:
            invalid.append(f"{field}={value}")
        elif field == "workflow_step":
            seen_workflow_step = True
            if value not in workflow_steps:
                invalid.append(f"{field}={value}")

    if axis_ok and not seen_workflow_step:
        report.fail("Pipeline file has no workflow_step values")
        axis_ok = False

    if invalid:
        report.fail(f"Pipeline values outside rules.yaml: {', '.join(invalid)}")
    elif axis_ok:
        report.pass_("Pipeline state, phase, phase_status, and workflow_step values match rules.yaml")


def check_ci(root: Path, rules: dict[str, dict[str, Any]], report: Report) -> None:
    workflow = root / str(rules["ci"]["workflow"])
    if not workflow.exists():
        report.fail(f"CI workflow missing: {workflow}")
        return

    jobs = set(re.findall(r"^  ([A-Za-z0-9_-]+):\s*$", workflow.read_text(encoding="utf-8"), re.MULTILINE))
    required = set(as_list(rules["ci"]["required_jobs"]))
    missing = sorted(required - jobs)
    if missing:
        report.fail(f"CI jobs missing: {', '.join(missing)}")
    else:
        report.pass_("CI required jobs are present")


def check_stale_literals(root: Path, report: Report) -> None:
    targets = [
        root / ".github/workflows/goal-ci.yml",
        root / "docs/goal/tools/matrix-gen.py",
        root / "docs/goal/tools/gate-check.sh",
        root / "docs/goal/tools/lint-goal.sh",
        root / "docs/goal/tools/evidence-collect.sh",
    ]
    stale_patterns = [
        (re.compile(r"\.config/goal/matrix\.yaml"), "old flat matrix path"),
        (re.compile(r"Done entries"), "old Matrix Done label"),
        (re.compile(r"Done\|Implemented\|Tested"), "old Matrix terminal status tuple"),
        (re.compile(r"current_state"), "old pipeline field current_state"),
        (re.compile(r"previous_state"), "old pipeline field previous_state"),
        (re.compile(r"MATRIX_READY"), "old matrix pipeline state"),
        (re.compile(r"CODE_GENERATED"), "old code pipeline state"),
        (re.compile(r"TEST_PASSED"), "old test pipeline state"),
        (re.compile(r"GOAL_READY"), "old goal pipeline state"),
        (re.compile(r"EXECUTING"), "old execution pipeline state"),
        (re.compile(r"VERIFYING"), "old verification pipeline state"),
    ]

    hits: list[str] = []
    for path in targets:
        if not path.exists():
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            for pattern, label in stale_patterns:
                if pattern.search(line):
                    hits.append(f"{path.relative_to(root)}:{number}: {label}")

    if hits:
        report.fail("Stale executable rule literals found: " + "; ".join(hits))
    else:
        report.pass_("No stale executable rule literals found")


def main() -> int:
    parser = argparse.ArgumentParser(description="Check Goal rule drift against rules.yaml")
    parser.add_argument("--root", default=".", help="repository root")
    parser.add_argument("--rules", default=".config/goal/schema/rules.yaml", help="rules.yaml path")
    parser.add_argument("--quiet", action="store_true", help="print failures only")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    rules_file = root / args.rules
    report = Report(args.quiet)

    if not rules_file.exists():
        print(f"[FAIL] rules.yaml missing: {rules_file}", file=sys.stderr)
        return 1

    rules = load_rules(rules_file)
    for section in [
        "module_goal_document",
        "module_code_location",
        "ids",
        "registry",
        "matrix",
        "evidence",
        "gate",
        "pipeline",
        "ci",
    ]:
        if section not in rules:
            report.fail(f"rules.yaml missing section: {section}")

    if not report.failures:
        check_schema_rules(rules, report)
        check_module_code_location(root, rules, report)
        check_registry(root, rules, report)
        evidence_refs = check_matrix(root, rules, report)
        check_evidence(root, rules, evidence_refs, report)
        check_gates(root, rules, report)
        check_pipeline(root, rules, report)
        check_ci(root, rules, report)
        check_stale_literals(root, report)

    if report.failures:
        if args.quiet:
            for failure in report.failures:
                print(f"[FAIL] {failure}")
        return 1

    if not args.quiet:
        print("[PASS] Goal rule drift check passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
