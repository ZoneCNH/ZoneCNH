"""
arbiter.py 端到端测试

构造 4 个 scores/*.json，运行 arbiter，验证 verdict 与 next_action。
"""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]


def _load():
    spec = importlib.util.spec_from_file_location("arbiter", ROOT / "scripts/arbiter.py")
    mod = importlib.util.module_from_spec(spec)
    sys.modules["arbiter"] = mod
    spec.loader.exec_module(mod)
    return mod


ar = _load()


@pytest.fixture
def env(tmp_path, monkeypatch):
    monkeypatch.setattr(ar, "ROOT", tmp_path)
    return tmp_path


def _write_scores(env_path: Path, module: str, stage: str, scores: dict[str, dict]):
    d = env_path / ".omc/state/pipeline" / module / stage / "scores"
    d.mkdir(parents=True, exist_ok=True)
    for src, payload in scores.items():
        (d / f"{src}.json").write_text(json.dumps(payload), encoding="utf-8")


def _full_scores(s_claude=99, s_codex=99, s_copilot=99, s_rules=99, redlines=None, confs=None):
    redlines = redlines or {}
    confs = confs or {}
    base = {
        "claude": {"score": s_claude, "redline": redlines.get("claude", False), "confidence": confs.get("claude", "high")},
        "codex": {"score": s_codex, "redline": redlines.get("codex", False), "confidence": confs.get("codex", "high")},
        "copilot": {"score": s_copilot, "redline": redlines.get("copilot", False), "confidence": confs.get("copilot", "high")},
        "rules": {"score": s_rules, "redline": redlines.get("rules", False), "confidence": confs.get("rules", "high")},
    }
    return base


# ---- pass ----


def test_all_pass(env):
    _write_scores(env, "m1", "matrix", _full_scores())
    v = ar.arbitrate("m1", "matrix", 3, 18)
    assert v["gate"] == "pass"
    assert v["next_action"] == "advance_to_next_stage"
    assert v["composite_score"] == 99


def test_spec_pass_auto_approve(env):
    _write_scores(env, "m1", "spec", _full_scores(98, 98, 98, 98))
    v = ar.arbitrate("m1", "spec", 3, 18)
    assert v["gate"] == "pass"
    assert v["next_action"] == "advance_to_next_stage_and_approve_spec"


# ---- fail: missing ----


def test_missing_source(env):
    _write_scores(env, "m1", "matrix", {
        "claude": {"score": 99, "redline": False, "confidence": "high"},
        "codex": {"score": 99, "redline": False, "confidence": "high"},
        # 缺 copilot 和 rules
    })
    v = ar.arbitrate("m1", "matrix", 3, 18)
    assert v["gate"] == "fail"
    assert any("missing_platform_score" in r for r in v["reasons"])
    assert v["next_action"] == "route_to_missing_platform_scorer"


# ---- fail: redline ----


def test_redline(env):
    _write_scores(env, "m1", "matrix", _full_scores(redlines={"claude": True}))
    v = ar.arbitrate("m1", "matrix", 3, 18)
    assert v["gate"] == "fail"
    assert "redline_present" in v["reasons"]
    assert v["next_action"] == "route_to_executor_for_repair"
    assert len(v["redlines"]) == 1


# ---- fail: composite < 98 ----


def test_low_score(env):
    _write_scores(env, "m1", "matrix", _full_scores(97, 99, 99, 99))
    v = ar.arbitrate("m1", "matrix", 3, 18)
    assert v["gate"] == "fail"
    assert any("composite_score(97)" in r for r in v["reasons"])
    assert v["composite_score"] == 97


# ---- fail: low confidence ----


def test_low_confidence(env):
    _write_scores(env, "m1", "matrix", _full_scores(confs={"codex": "low"}))
    v = ar.arbitrate("m1", "matrix", 3, 18)
    assert v["gate"] == "fail"
    assert v["next_action"] == "route_to_low_confidence_scorer_for_rerun"


def test_rules_low_confidence_not_blocking(env):
    """rules 源 low confidence 仅诊断不参与 gate"""
    _write_scores(env, "m1", "code", _full_scores(confs={"rules": "low"}))
    v = ar.arbitrate("m1", "code", 3, 18)
    assert v["gate"] == "pass"


# ---- fail: spread ----


def test_score_spread(env):
    _write_scores(env, "m1", "matrix", _full_scores(99, 99, 92, 99))  # llm spread = 7
    v = ar.arbitrate("m1", "matrix", 3, 18)
    assert v["gate"] == "fail"
    assert v["next_action"] == "route_to_scorers_for_reconciliation"


# ---- fail: heterogeneous divergence ----


def test_heterogeneous_divergence(env):
    _write_scores(env, "m1", "matrix", _full_scores(99, 99, 99, 50))
    v = ar.arbitrate("m1", "matrix", 3, 18)
    assert v["gate"] == "fail"
    assert v["heterogeneous_divergence"] == 49
    assert v["next_action"] == "route_to_meta_arbiter_for_diagnosis"


# ---- 失败循环 ----


def test_stage_attempt_exhausted_routes_back(env):
    # 3 次失败 → 路由回上一阶段
    for _ in range(3):
        _write_scores(env, "m1", "matrix", _full_scores(95, 99, 99, 99))
        ar.arbitrate("m1", "matrix", 3, 18)
    last = json.loads((env / ".omc/state/pipeline/m1/matrix/verdict.json").read_text())
    assert last["next_action"] == "route_back_to_spec"


def test_spec_failure_loops_to_rewrite(env):
    for _ in range(3):
        _write_scores(env, "m1", "spec", _full_scores(95, 99, 99, 99))
        ar.arbitrate("m1", "spec", 3, 18)
    last = json.loads((env / ".omc/state/pipeline/m1/spec/verdict.json").read_text())
    assert last["next_action"] == "route_back_to_spec_executor_for_rewrite"


def test_total_budget_exhausted(env):
    for _ in range(18):
        _write_scores(env, "m1", "matrix", _full_scores(95, 99, 99, 99))
        ar.arbitrate("m1", "matrix", 100, 18)  # 大 stage 限制只测总预算
    last = json.loads((env / ".omc/state/pipeline/m1/matrix/verdict.json").read_text())
    assert last["next_action"] == "pipeline_blocked_for_retrospective"


# ---- verdict schema ----


def test_verdict_schema(env):
    _write_scores(env, "m1", "matrix", _full_scores())
    v = ar.arbitrate("m1", "matrix", 3, 18)
    for k in ("module", "stage", "arbitrated_at", "scores", "composite_score",
              "score_range", "heterogeneous_divergence", "redlines", "gate",
              "reasons", "next_action", "attempt", "repair_budget", "arbiter_engine"):
        assert k in v
    assert v["arbiter_engine"] == "deterministic-1.0"
    for src in ("claude", "codex", "copilot", "rules"):
        assert src in v["scores"]
