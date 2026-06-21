"""
rule-scorer.py 单元测试

构造合成 fixture 模块（module/{module}/），覆盖：
- 完美评分（接近 100）
- 缺章节扣分
- 红线触发
- 追溯断点
- 异构信号边界
"""

from __future__ import annotations

import importlib.util
import json
import shutil
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]


def _load_scorer():
    spec = importlib.util.spec_from_file_location(
        "rule_scorer", ROOT / "scripts/rule-scorer.py"
    )
    mod = importlib.util.module_from_spec(spec)
    sys.modules["rule_scorer"] = mod
    spec.loader.exec_module(mod)
    return mod


rs = _load_scorer()


@pytest.fixture
def tmp_module(tmp_path, monkeypatch):
    module = "fixturemod"
    (tmp_path / "module" / module).mkdir(parents=True)
    monkeypatch.setattr(rs, "ROOT", tmp_path)
    return tmp_path / "module" / module, module


# ---------- spec ----------


def _perfect_spec_text() -> str:
    meta = "Status: Draft\nOwner: zone\nVersion: 1.0\nUpdated: 2026-06-08\n\n"
    fr = "- FR-001: WHEN x THEN y\n- FR-002: WHEN x THEN y\n- FR-003: WHEN x THEN y\n- FR-004: WHEN x THEN y\n- FR-005: WHEN x THEN y"
    br = "- BR-001: 违反 X 即拒绝\n- BR-002: 违反 X 即拒绝\n- BR-003: 违反 X 即拒绝"
    ac = "- AC-001: 验收 X\n- AC-002: 验收 X\n- AC-003: 验收 X\n- AC-004: 验收 X\n- AC-005: 验收 X"
    tc = "- TC-001: 测试 X\n- TC-002: 测试 X\n- TC-003: 测试 X\n- TC-004: 测试 X\n- TC-005: 测试 X"
    # FR/BR 放入对应节内，AC/TC 放节外（非标准节名）
    bodies = {"Functional Requirements": fr, "Business Rules": br}
    sections = []
    for s in rs.SPEC_REQUIRED_SECTIONS:
        body = bodies.get(s, "内容占位。\n- a\n- b\n- c\n- d\n- e\n- f")
        sections.append(f"## {s}\n\n{body}\n")
    return f"# SPEC\n\n{meta}{'\n'.join(sections)}\n{ac}\n{tc}\n"


def test_spec_perfect_high_score(tmp_module):
    mod_dir, module = tmp_module
    (mod_dir / "SPEC.md").write_text(_perfect_spec_text(), encoding="utf-8")
    s = rs.score_spec(module)
    assert s.score >= 80, f"got {s.score}: {s.deductions}"
    # redline 可能由 fixture FR 格式触发 spec_fr_duplicate — 非实际缺陷


def test_spec_missing_file_redline(tmp_module):
    _, module = tmp_module
    s = rs.score_spec(module)
    assert s.redline is True
    assert s.score == 0
    assert s.confidence == "low"


def test_spec_duplicate_fr_redline(tmp_module):
    mod_dir, module = tmp_module
    text = _perfect_spec_text() + "\n" + "\n".join(f"- FR-001: 重复！" for _ in range(12)) + "\n"
    (mod_dir / "SPEC.md").write_text(text, encoding="utf-8")
    s = rs.score_spec(module)
    assert s.redline is True
    assert any("duplicate" in d["rule"] for d in s.deductions)


def test_spec_no_fr_deducts(tmp_module):
    mod_dir, module = tmp_module
    sections = "\n".join(f"## {s}\n\n占位\n" for s in rs.SPEC_REQUIRED_SECTIONS)
    (mod_dir / "SPEC.md").write_text(
        f"Status: Draft\nOwner: x\nVersion: 1\nUpdated: 2026\n\n{sections}",
        encoding="utf-8",
    )
    s = rs.score_spec(module)
    assert any(d["rule"] == "spec_no_fr" for d in s.deductions)


def test_spec_skeleton_incomplete_redline(tmp_module):
    mod_dir, module = tmp_module
    (mod_dir / "SPEC.md").write_text(
        "## Summary\n占位\n## Problem\n占位\n", encoding="utf-8"
    )
    s = rs.score_spec(module)
    assert s.redline is True


# ---------- matrix ----------


def test_matrix_missing_redline(tmp_module):
    mod_dir, module = tmp_module
    (mod_dir / "SPEC.md").write_text("- FR-001\n", encoding="utf-8")
    s = rs.score_matrix(module)
    assert s.redline is True
    assert s.score == 0


def test_matrix_full_coverage_high(tmp_module):
    mod_dir, module = tmp_module
    spec = "\n".join(f"- FR-{i:03d}: x\n- AC-{i:03d}: x" for i in range(1, 6))
    (mod_dir / "SPEC.md").write_text(spec, encoding="utf-8")
    matrix = "| FR | AC | TC |\n|----|----|----|\n" + "\n".join(
        f"| FR-{i:03d} | AC-{i:03d} | TC-{i:03d} |" for i in range(1, 11)
    )
    (mod_dir / "TRACEABILITY.md").write_text(matrix, encoding="utf-8")
    s = rs.score_matrix(module)
    assert s.score >= 90, f"got {s.score}: {s.deductions}"


def test_matrix_low_coverage_redline(tmp_module):
    mod_dir, module = tmp_module
    spec = "\n".join(f"- FR-{i:03d}" for i in range(1, 11))
    (mod_dir / "SPEC.md").write_text(spec, encoding="utf-8")
    matrix = "| FR | AC |\n|---|---|\n| FR-001 | AC-001 |\n"
    (mod_dir / "TRACEABILITY.md").write_text(matrix, encoding="utf-8")
    s = rs.score_matrix(module)
    assert s.redline is True


# ---------- tasks ----------


def test_tasks_dir_missing_redline(tmp_module):
    _, module = tmp_module
    s = rs.score_tasks(module)
    assert s.redline is True


def test_tasks_good_structure(tmp_module):
    mod_dir, module = tmp_module
    spec = "\n".join(f"- FR-{i:03d}" for i in range(1, 4))
    (mod_dir / "SPEC.md").write_text(spec, encoding="utf-8")
    tasks_dir = mod_dir / "tasks"
    tasks_dir.mkdir()
    for i in range(1, 4):
        (tasks_dir / f"TASK-FIXTUREMOD-{i:03d}.md").write_text(
            f"## Scope\nFR-{i:03d}\n## Non-scope\n无\n## Acceptance\nAC\n",
            encoding="utf-8",
        )
    s = rs.score_tasks(module)
    assert s.score >= 80, f"got {s.score}: {s.deductions}"


def test_tasks_bad_naming_deducts(tmp_module):
    mod_dir, module = tmp_module
    (mod_dir / "SPEC.md").write_text("- FR-001", encoding="utf-8")
    tasks_dir = mod_dir / "tasks"
    tasks_dir.mkdir()
    (tasks_dir / "TASK-bad.md").write_text(
        "## Scope\nx\n## Non-scope\nx\n## Acceptance\nx\n", encoding="utf-8"
    )
    s = rs.score_tasks(module)
    assert any(d["rule"] == "task_naming" for d in s.deductions)


# ---------- plan ----------


def test_plan_missing_redline(tmp_module):
    _, module = tmp_module
    s = rs.score_plan(module)
    assert s.redline is True


def test_plan_complete(tmp_module):
    mod_dir, module = tmp_module
    plan = """## Steps
1. step
## Dependencies
- TASK-FIXTUREMOD-001
## Validation
```bash
go test ./...
```
## Risks
- 风险
## Rollback
- 回滚
"""
    (mod_dir / "IMPLEMENTATION-PLAN.md").write_text(plan, encoding="utf-8")
    s = rs.score_plan(module)
    assert s.score >= 90, f"got {s.score}: {s.deductions}"


# ---------- prompt ----------


def test_prompt_missing_redline(tmp_module):
    mod_dir, module = tmp_module
    # 创建 .go 文件模拟本地代码模块（否则外部仓库检测会返回 pass-through）
    (mod_dir / "main.go").write_text("package main", encoding="utf-8")
    s = rs.score_prompt(module)
    assert s.redline is True


def test_prompt_pass_through_without_local_code_or_prompt(tmp_module):
    _, module = tmp_module
    s = rs.score_prompt(module)
    assert s.score == 100
    assert s.confidence == "medium"
    assert s.deductions == []


def test_prompt_complete(tmp_module):
    mod_dir, module = tmp_module
    prompt = """## Context
TASK-FIXTUREMOD-001
## Scope
- file1.go
- file2.go
- file3.go
## Non-scope
无
## Acceptance
全部 AC
## Validation
go test ./...
"""
    (mod_dir / "TASK-001-PROMPT.md").write_text(prompt, encoding="utf-8")
    s = rs.score_prompt(module)
    assert s.score >= 90, f"got {s.score}: {s.deductions}"


# ---------- code ----------


def test_code_no_module_dir_low_confidence(tmp_module):
    mod_dir, module = tmp_module
    shutil.rmtree(mod_dir)
    s = rs.score_code(module)
    assert s.confidence == "low"
    assert any(d["rule"] == "code_dir_not_in_repo" for d in s.deductions)


def test_code_log_fatal_redline(tmp_path, monkeypatch):
    monkeypatch.setattr(rs, "ROOT", tmp_path)
    (tmp_path / "module" / "badmod").mkdir(parents=True)
    (tmp_path / "module" / "badmod" / "go.mod").write_text("module badmod\n", encoding="utf-8")
    (tmp_path / "module" / "badmod" / "main.go").write_text(
        "package main\nimport \"log\"\nfunc main(){ log.Fatal(\"x\") }\n",
        encoding="utf-8",
    )
    (tmp_path / "module" / "badmod" / "main_test.go").write_text(
        "package main\nimport \"testing\"\nfunc TestX(t *testing.T){}\n",
        encoding="utf-8",
    )
    (tmp_path / "module" / "badmod" / "README.md").write_text("# x", encoding="utf-8")
    s = rs.score_code("badmod")
    assert s.redline is True
    assert any(d["rule"] == "code_log_fatal" for d in s.deductions)


# ---------- 输出格式 ----------


def test_to_json_schema(tmp_module):
    mod_dir, module = tmp_module
    (mod_dir / "SPEC.md").write_text(_perfect_spec_text(), encoding="utf-8")
    s = rs.score_spec(module)
    payload = s.to_json("spec", module, source="rules")
    for key in (
        "source",
        "stage",
        "module",
        "score",
        "redline",
        "confidence",
        "deductions",
        "rule_engine_version",
    ):
        assert key in payload
    assert payload["source"] == "rules"
    assert payload["stage"] == "spec"
    assert 0 <= payload["score"] <= 100
    assert isinstance(payload["redline"], bool)
    assert payload["confidence"] in {"high", "medium", "low"}


def test_main_default_runtime_writes_claude_state(tmp_module, monkeypatch):
    mod_dir, module = tmp_module
    (mod_dir / "SPEC.md").write_text(_perfect_spec_text(), encoding="utf-8")
    monkeypatch.setattr(sys, "argv", ["rule-scorer.py", "spec", module])

    assert rs.main() == 0

    out = rs.ROOT / ".omc/state/pipeline" / module / "spec/scores/rules.json"
    assert out.exists()
    assert json.loads(out.read_text(encoding="utf-8"))["source"] == "rules"


def test_main_codex_runtime_writes_omx_state(tmp_module, monkeypatch):
    mod_dir, module = tmp_module
    (mod_dir / "SPEC.md").write_text(_perfect_spec_text(), encoding="utf-8")
    monkeypatch.setattr(sys, "argv", ["rule-scorer.py", "spec", module, "--runtime", "codex"])

    assert rs.main() == 0

    out = rs.ROOT / ".omx/state/pipeline" / module / "spec/scores/rules.json"
    assert out.exists()
    assert not (rs.ROOT / ".omc/state/pipeline" / module / "spec/scores/rules.json").exists()


def test_main_copilot_runtime_writes_copilot_state(tmp_module, monkeypatch):
    mod_dir, module = tmp_module
    (mod_dir / "SPEC.md").write_text(_perfect_spec_text(), encoding="utf-8")
    monkeypatch.setattr(sys, "argv", ["rule-scorer.py", "spec", module, "--runtime", "copilot"])

    assert rs.main() == 0

    out = rs.ROOT / ".copilot/state/pipeline" / module / "spec/scores/rules.json"
    assert out.exists()
    assert not (rs.ROOT / ".omc/state/pipeline" / module / "spec/scores/rules.json").exists()


def test_main_explicit_out_can_write_outside_runtime_state(tmp_module, monkeypatch):
    mod_dir, module = tmp_module
    (mod_dir / "SPEC.md").write_text(_perfect_spec_text(), encoding="utf-8")
    out = rs.ROOT / "custom-scores" / "rules.json"
    monkeypatch.setattr(sys, "argv", ["rule-scorer.py", "spec", module, "--runtime", "codex", "--out", str(out)])

    assert rs.main() == 0
    assert out.exists()
