"""Regression tests for scripts/governance-lint.py."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "governance-lint.py"


def _load():
    spec = importlib.util.spec_from_file_location("governance_lint", SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    sys.modules["governance_lint"] = mod
    spec.loader.exec_module(mod)
    return mod


gl = _load()


def test_stale_absolute_path_detector_flags_tracked_text(tmp_path):
    rel = Path("docs/example.md")
    path = tmp_path / rel
    path.parent.mkdir(parents=True)
    path.write_text(f"cd {gl.STALE_PREFIX}\n", encoding="utf-8")

    findings = gl.find_stale_absolute_paths(tmp_path, [rel])

    assert len(findings) == 1
    assert findings[0].check == "stale-path"
    assert findings[0].path == rel


def test_runtime_state_roots_are_consistent_across_pipeline_tools():
    assert gl.check_runtime_roots(ROOT) == []


def test_required_validation_wiring_is_present():
    assert gl.check_required_validation_wiring(ROOT) == []


def test_repo_governance_lint_passes_current_tracked_text():
    assert gl.run_checks(ROOT) == []
