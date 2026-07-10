"""Regression tests for outer-metrics spec path handling."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def test_outer_metrics_workflow_prefers_directory_spec_layout():
    workflow = (ROOT / ".github" / "workflows" / "outer-metrics.yml").read_text(encoding="utf-8")

    assert "module_dir/spec/SPEC.md" in workflow
    assert "module_dir/SPEC.md" in workflow
    assert "spec/SPEC.md" in workflow


def test_outer_metrics_git_collector_prefers_directory_spec_layout():
    script = (ROOT / "scripts" / "outer-metrics-from-git.sh").read_text(encoding="utf-8")

    assert 'SPEC_PATH="$MODULE_DIR/spec/SPEC.md"' in script
    assert 'SPEC_PATH="$MODULE_DIR/SPEC.md"' in script
    assert 'git log -1 --format=\'%H\' -- "$SPEC_PATH"' in script
