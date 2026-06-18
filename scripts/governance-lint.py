#!/usr/bin/env python3
"""Minimal governance lint for repo-local path/runtime/evidence guardrails.

This script intentionally checks guardrail wiring only. It is not a Factory/GK
release gate and must not be used as release proof.
"""

from __future__ import annotations

import ast
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STALE_PREFIX = "/home/" + "ZoneCNH-kernel-governance-evidence"
EXPECTED_RUNTIME_ROOTS = {
    "claude": ".omc/state/pipeline",
    "codex": ".omx/state/pipeline",
    "copilot": ".copilot/state/pipeline",
}
RUNTIME_ROOT_FILES = (
    Path("scripts/pipeline.py"),
    Path("scripts/arbiter.py"),
    Path("scripts/rule-scorer.py"),
)
TEXT_SUFFIXES = {
    "",
    ".bash",
    ".cfg",
    ".csv",
    ".json",
    ".md",
    ".mjs",
    ".py",
    ".sh",
    ".txt",
    ".yaml",
    ".yml",
}


@dataclass(frozen=True)
class Finding:
    check: str
    path: Path
    line: int
    message: str

    def format(self) -> str:
        rel = self.path if self.path.is_absolute() else self.path.as_posix()
        return f"{self.check}: {rel}:{self.line}: {self.message}"


def _run_git_ls_files(root: Path = ROOT) -> list[Path]:
    try:
        result = subprocess.run(
            ["git", "ls-files"],
            cwd=root,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except (OSError, subprocess.CalledProcessError):
        return []
    return [Path(line) for line in result.stdout.splitlines() if line]


def tracked_text_files(root: Path = ROOT) -> list[Path]:
    files = _run_git_ls_files(root)
    if not files:
        files = [p.relative_to(root) for p in root.rglob("*") if p.is_file() and ".git" not in p.parts]
    return sorted(
        p
        for p in files
        if p.suffix in TEXT_SUFFIXES and not any(part in {".git", "node_modules"} for part in p.parts)
    )


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def find_stale_absolute_paths(root: Path = ROOT, files: list[Path] | None = None) -> list[Finding]:
    findings: list[Finding] = []
    for rel in files or tracked_text_files(root):
        path = root / rel
        try:
            lines = _read_text(path).splitlines()
        except UnicodeDecodeError:
            continue
        for idx, line in enumerate(lines, start=1):
            if STALE_PREFIX in line:
                findings.append(
                    Finding(
                        "stale-path",
                        rel,
                        idx,
                        f"replace stale absolute workspace prefix {STALE_PREFIX!r} with a repo-relative path or <repo-root>",
                    )
                )
    return findings


def _literal_assignment(path: Path, name: str):
    tree = ast.parse(_read_text(path), filename=str(path))
    for node in tree.body:
        if isinstance(node, ast.Assign):
            if any(isinstance(target, ast.Name) and target.id == name for target in node.targets):
                return ast.literal_eval(node.value)
        if isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name) and node.target.id == name:
            return ast.literal_eval(node.value)
    raise KeyError(f"{name} not found in {path}")


def check_runtime_roots(root: Path = ROOT) -> list[Finding]:
    findings: list[Finding] = []
    for rel in RUNTIME_ROOT_FILES:
        path = root / rel
        try:
            roots = _literal_assignment(path, "RUNTIME_STATE_ROOTS")
        except Exception as exc:  # pragma: no cover - message validated through caller
            findings.append(Finding("runtime-roots", rel, 1, f"cannot parse RUNTIME_STATE_ROOTS: {exc}"))
            continue
        if roots != EXPECTED_RUNTIME_ROOTS:
            findings.append(
                Finding(
                    "runtime-roots",
                    rel,
                    1,
                    f"expected {EXPECTED_RUNTIME_ROOTS!r}, found {roots!r}",
                )
            )
    return findings


def check_required_validation_wiring(root: Path = ROOT) -> list[Finding]:
    """Verify existing governance validators still encode the minimum rules."""
    required_patterns: tuple[tuple[str, Path, str, str], ...] = (
        (
            "task-id-format",
            Path(".github/ci/task-spec-validate.sh"),
            r"TASK-\[A-Z\]\+\-\[0-9\]\{3\}",
            "task validation must enforce TASK-{MODULE}-{NNN} ID shape",
        ),
        (
            "task-status-stale",
            Path(".github/ci/task-spec-validate.sh"),
            r"status=.*in_progress|in_progress",
            "task validation must inspect in_progress status staleness",
        ),
        (
            "evidence-promotion",
            Path("docs/goal/tools/matrix-gen.py"),
            r"status == \"Verified\" and not evidence_ids",
            "Verified matrix edges must require evidence_id before promotion",
        ),
        (
            "status-vocabulary",
            Path("docs/goal/tools/matrix-gen.py"),
            r"EDGE_STATUSES\s*=\s*\{[^}]*Verified[^}]*Dropped[^}]*Blocked",
            "matrix status vocabulary must include terminal/blocking statuses",
        ),
        (
            "gate-check-evidence",
            Path("docs/goal/tools/gate-check.sh"),
            r"Verified edge 缺少 evidence_id|verified_without_evidence",
            "shell gate must fail Verified edges that lack evidence_id",
        ),
        (
            "team-worktree-clean",
            Path("scripts/auto-deliver-on-complete.sh"),
            r"git -C \"\$main_worktree\" status --porcelain",
            "team auto-delivery must validate main worktree cleanliness",
        ),
        (
            "team-worktree-boundary",
            Path("scripts/auto-deliver-on-complete.sh"),
            r"git worktree list --porcelain",
            "team auto-delivery must resolve worktree boundaries explicitly",
        ),
    )
    findings: list[Finding] = []
    for check, rel, pattern, message in required_patterns:
        text = _read_text(root / rel)
        if not re.search(pattern, text, flags=re.S):
            findings.append(Finding(check, rel, 1, message))
    return findings


def run_checks(root: Path = ROOT) -> list[Finding]:
    findings: list[Finding] = []
    findings.extend(find_stale_absolute_paths(root))
    findings.extend(check_runtime_roots(root))
    findings.extend(check_required_validation_wiring(root))
    return findings


def main() -> int:
    findings = run_checks(ROOT)
    if findings:
        print("governance-lint: FAIL")
        for finding in findings:
            print(f"- {finding.format()}")
        return 1
    print("governance-lint: PASS")
    print(f"- stale-path: no tracked text file contains {STALE_PREFIX!r}")
    print("- runtime-roots: claude/codex/copilot state roots match across pipeline/arbiter/rule-scorer")
    print("- validation-wiring: task ID/status, evidence promotion, and team worktree guardrails are present")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
