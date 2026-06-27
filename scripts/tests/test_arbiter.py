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


def _write_scores(env_path: Path, module: str, stage: str, scores: dict[str, dict], runtime: str = "claude"):
    d = ar.state_root(runtime) / module / stage / "scores"
    d.mkdir(parents=True, exist_ok=True)
    for src, payload in scores.items():
        (d / f"{src}.json").write_text(json.dumps(payload), encoding="utf-8")


def _score_payload(source, module, stage, score, redline=False, confidence="high"):
    return {
        "source": source,
        "module": module,
        "stage": stage,
        "score": score,
        "redline": redline,
        "confidence": confidence,
        "deductions": [],
    }


def _full_scores(
    s_claude=99,
    s_codex=99,
    s_copilot=99,
    s_rules=99,
    redlines=None,
    confs=None,
    module="m1",
    stage="matrix",
):
    redlines = redlines or {}
    confs = confs or {}
    base = {
        "claude": _score_payload("claude", module, stage, s_claude, redlines.get("claude", False), confs.get("claude", "high")),
        "codex": _score_payload("codex", module, stage, s_codex, redlines.get("codex", False), confs.get("codex", "high")),
        "copilot": _score_payload("copilot", module, stage, s_copilot, redlines.get("copilot", False), confs.get("copilot", "high")),
        "rules": _score_payload("rules", module, stage, s_rules, redlines.get("rules", False), confs.get("rules", "high")),
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
    _write_scores(env, "m1", "spec", _full_scores(98, 98, 98, 98, stage="spec"))
    v = ar.arbitrate("m1", "spec", 3, 18)
    assert v["gate"] == "pass"
    assert v["next_action"] == "advance_to_next_stage_and_approve_spec"


# ---- fail: missing ----


def test_missing_source(env):
    _write_scores(env, "m1", "matrix", {
        "claude": _score_payload("claude", "m1", "matrix", 99),
        "codex": _score_payload("codex", "m1", "matrix", 99),
        # 缺 copilot 和 rules
    })
    v = ar.arbitrate("m1", "matrix", 3, 18)
    assert v["gate"] == "fail"
    assert any("missing_score_source" in r for r in v["reasons"])
    assert v["next_action"] == "route_to_missing_score_source"


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
    _write_scores(env, "m1", "matrix", _full_scores(80, 99, 99, 99))
    v = ar.arbitrate("m1", "matrix", 3, 18)
    assert v["gate"] == "fail"
    assert any("composite_score(80)" in r for r in v["reasons"])
    assert v["composite_score"] == 80


# ---- fail: low confidence ----


def test_low_confidence(env):
    _write_scores(env, "m1", "matrix", _full_scores(confs={"codex": "low"}))
    v = ar.arbitrate("m1", "matrix", 3, 18)
    assert v["gate"] == "fail"
    assert v["next_action"] == "route_to_low_confidence_scorer_for_rerun"


def test_rules_low_confidence_not_blocking(env):
    """rules 源 low confidence 仅诊断不参与 gate"""
    _write_scores(env, "m1", "code", _full_scores(confs={"rules": "low"}, stage="code"))
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
        _write_scores(env, "m1", "matrix", _full_scores(80, 99, 99, 99))
        ar.arbitrate("m1", "matrix", 3, 18)
    last = json.loads((ar.state_root("claude") / "m1/matrix/verdict.json").read_text())
    assert last["next_action"] == "route_back_to_spec"


def test_spec_failure_loops_to_rewrite(env):
    for _ in range(3):
        _write_scores(env, "m1", "spec", _full_scores(80, 99, 99, 99, stage="spec"))
        ar.arbitrate("m1", "spec", 3, 18)
    last = json.loads((ar.state_root("claude") / "m1/spec/verdict.json").read_text())
    assert last["next_action"] == "route_back_to_spec_executor_for_rewrite"


def test_total_budget_exhausted(env):
    for _ in range(18):
        _write_scores(env, "m1", "matrix", _full_scores(80, 99, 99, 99))
        ar.arbitrate("m1", "matrix", 100, 18)  # 大 stage 限制只测总预算
    last = json.loads((ar.state_root("claude") / "m1/matrix/verdict.json").read_text())
    assert last["next_action"] == "pipeline_blocked_for_retrospective"


# ---- force deprecation: --force never produces gate=pass ----


def test_force_missing_source_still_fails(env):
    """--force with missing sources must produce gate=fail with force_override=True."""
    _write_scores(env, "m1", "matrix", {
        "claude": _score_payload("claude", "m1", "matrix", 99),
        "codex": _score_payload("codex", "m1", "matrix", 99),
        "rules": _score_payload("rules", "m1", "matrix", 99),
        # 缺 copilot
    })
    v = ar.arbitrate("m1", "matrix", 3, 18, force=True)
    assert v["gate"] == "fail"
    assert v["force_override"] is True
    assert any("forced_missing_source" in r for r in v["reasons"])
    assert v["next_action"] == "route_to_missing_score_source"


def test_force_all_sources_pass_ignores_force(env):
    """--force with all 4 sources present should behave normally (force_override=False)."""
    _write_scores(env, "m1", "matrix", _full_scores())
    v = ar.arbitrate("m1", "matrix", 3, 18, force=True)
    assert v["gate"] == "pass"
    assert v["force_override"] is False


def test_force_no_llm_source_fails(env):
    """--force with only rules source (no LLM) must fail."""
    _write_scores(env, "m1", "matrix", {
        "rules": _score_payload("rules", "m1", "matrix", 99),
        # 缺所有 LLM 源
    })
    v = ar.arbitrate("m1", "matrix", 3, 18, force=True)
    assert v["gate"] == "fail"
    assert v["force_override"] is True
    assert v["composite_score"] == 0


# ---- PASS_WITH_RISK: composite 85-97 on allowed Gate ----


def test_pass_with_risk_allowed_gate(env):
    """composite 85-97 on G2/G4/G5 (allowed) → PASS_WITH_RISK."""
    _write_scores(env, "m1", "spec", _full_scores(s_claude=90, s_codex=90, s_copilot=90, s_rules=90, stage="spec"))
    v = ar.arbitrate("m1", "spec", 3, 18)
    assert v["gate"] == "pass_with_risk"
    assert v["next_action"] == "advance_to_next_stage_with_risk_register"
    assert any("pass_with_risk" in r for r in v["reasons"])
    assert v["scoring_thresholds"]["stage_gate"] == "G2"


def test_pass_with_risk_not_allowed_g6(env):
    """composite 85-97 on G6 (prompt/code, not allowed) → FAIL."""
    _write_scores(env, "m1", "code", _full_scores(s_claude=90, s_codex=90, s_copilot=90, s_rules=90, stage="code"))
    v = ar.arbitrate("m1", "code", 3, 18)
    assert v["gate"] == "fail"
    assert any("pass_with_risk_not_allowed" in r for r in v["reasons"])


def test_pass_with_risk_below_min_fails(env):
    """composite < 85 → FAIL (not PASS_WITH_RISK)."""
    _write_scores(env, "m1", "spec", _full_scores(s_claude=80, s_codex=80, s_copilot=80, s_rules=80, stage="spec"))
    v = ar.arbitrate("m1", "spec", 3, 18)
    assert v["gate"] == "fail"


def test_pass_with_risk_redline_blocks(env):
    """Redline present → FAIL even if composite >= 85."""
    _write_scores(env, "m1", "spec",
                  _full_scores(s_claude=90, s_codex=90, s_copilot=90, s_rules=90,
                               redlines={"claude": True}, stage="spec"))
    v = ar.arbitrate("m1", "spec", 3, 18)
    assert v["gate"] == "fail"
    assert "redline_present" in v["reasons"]


# ---- verdict schema ----


def test_verdict_schema(env):
    _write_scores(env, "m1", "matrix", _full_scores())
    v = ar.arbitrate("m1", "matrix", 3, 18)
    for k in ("module", "stage", "arbitrated_at", "scores", "composite_score",
              "score_range", "heterogeneous_divergence", "redlines", "gate",
              "reasons", "next_action", "attempt", "repair_budget", "arbiter_engine",
              "runtime", "state_root"):
        assert k in v
    assert v["arbiter_engine"] == "deterministic-1.0"
    for src in ("claude", "codex", "copilot", "rules"):
        assert src in v["scores"]


def test_codex_runtime_uses_omx_state(env):
    _write_scores(env, "m1", "matrix", _full_scores(), runtime="codex")
    v = ar.arbitrate("m1", "matrix", 3, 18, runtime="codex")
    assert v["gate"] == "pass"
    assert v["runtime"] == "codex"
    assert v["state_root"] == ".omx/state/pipeline"
    assert (env / ".omx/state/pipeline/m1/matrix/verdict.json").exists()
    assert not (env / ".omc/state/pipeline/m1/matrix/verdict.json").exists()


def test_copilot_runtime_uses_copilot_state(env):
    _write_scores(env, "m1", "matrix", _full_scores(), runtime="copilot")
    v = ar.arbitrate("m1", "matrix", 3, 18, runtime="copilot")
    assert v["gate"] == "pass"
    assert v["runtime"] == "copilot"
    assert v["state_root"] == ".copilot/state/pipeline"
    assert (env / ".copilot/state/pipeline/m1/matrix/verdict.json").exists()
    assert not (env / ".omc/state/pipeline/m1/matrix/verdict.json").exists()
