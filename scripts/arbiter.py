#!/usr/bin/env python3
"""
arbiter.py — 确定性仲裁器（替代/补充 LLM pipeline-arbiter agent）

严格按 docs/governance/scoring/ARBITER-PROTOCOL.md 算法实现：
1. 四源齐全（claude/codex/copilot/rules）
2. 无红线
3. composite_score = min(claude, codex, copilot, rules) >= composite_pass_threshold (默认 98)
4. LLM 置信度全 high
5. LLM 分差 <= llm_spread_max (默认 5)
6. 异构一致：|rules - median(LLM)| <= heterogeneous_divergence_max (默认 15)

阈值从 .config/goal/schema/rules.yaml scoring 段加载（SSOT），文件缺失时回退到硬编码默认值。
PASS_WITH_RISK 路径：pass_with_risk_min <= composite < pass_threshold 且对应 Gate 允许时，
gate=PASS_WITH_RISK，否则 gate=fail。

写出 verdict.json，更新 attempts.json，决定 next_action。

用法：
  arbiter.py <module> <stage> [--runtime claude|codex|copilot]
  arbiter.py <module> <stage> --runtime codex --max-stage-attempts 3 --max-total 18
"""

from __future__ import annotations

import argparse
import datetime as dt
import importlib.util
import json
import os
import statistics
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RUNTIME_STATE_ROOTS = {
    "claude": ".omc/state/pipeline",
    "codex": ".omx/state/pipeline",
    "copilot": ".copilot/state/pipeline",
}
LLM_SOURCES = ("claude", "codex", "copilot")
ALL_SOURCES = LLM_SOURCES + ("rules",)
STAGE_ORDER = ("spec", "matrix", "tasks", "plan", "prompt", "code")

# --- 阈值加载（从 rules.yaml scoring 段，SSOT） ---

_SCORING_DEFAULTS = {
    "composite_pass_threshold": 98,
    "composite_pass_with_risk_min": 85,
    "llm_spread_max": 5,
    "heterogeneous_divergence_max": 15,
    "max_stage_attempts": 3,
    "max_total_gate_failures": 18,
    "stage_gate_map": {
        "spec": "G2", "matrix": "G5", "tasks": "G5",
        "plan": "G4", "prompt": "G6", "code": "G6",
    },
    "no_pass_with_risk_gates": ["G6", "G10"],
    "gate_thresholds": {},
}


def _load_scoring_config() -> dict:
    """Load scoring thresholds from .config/goal/schema/rules.yaml."""
    rules_path = ROOT / ".config/goal/schema/rules.yaml"
    if not rules_path.exists():
        return dict(_SCORING_DEFAULTS)
    try:
        import yaml
        data = yaml.safe_load(rules_path.read_text(encoding="utf-8"))
        scoring = data.get("scoring", {})
        cfg = dict(_SCORING_DEFAULTS)
        for k in ("composite_pass_threshold", "composite_pass_with_risk_min",
                   "llm_spread_max", "heterogeneous_divergence_max",
                   "max_stage_attempts", "max_total_gate_failures"):
            if k in scoring:
                cfg[k] = scoring[k]
        if "stage_gate_map" in scoring:
            cfg["stage_gate_map"] = scoring["stage_gate_map"]
        if "no_pass_with_risk_gates" in scoring:
            cfg["no_pass_with_risk_gates"] = scoring["no_pass_with_risk_gates"]
        if "gate_thresholds" in scoring:
            cfg["gate_thresholds"] = scoring["gate_thresholds"]
        return cfg
    except Exception:
        return dict(_SCORING_DEFAULTS)


_SCORING = _load_scoring_config()


def _load_validator():
    spec = importlib.util.spec_from_file_location(
        "score_validator", ROOT / "scripts/score-validate.py"
    )
    mod = importlib.util.module_from_spec(spec)
    sys.modules.setdefault("score_validator", mod)
    spec.loader.exec_module(mod)
    return mod


_validator = _load_validator()


def default_runtime() -> str:
    runtime = os.environ.get("SPEC_PIPELINE_RUNTIME", "claude").lower()
    if runtime not in RUNTIME_STATE_ROOTS:
        allowed = ", ".join(sorted(RUNTIME_STATE_ROOTS))
        raise SystemExit(f"不支持的 SPEC_PIPELINE_RUNTIME={runtime!r}; 可选: {allowed}")
    return runtime


def state_root(runtime: str) -> Path:
    return ROOT / RUNTIME_STATE_ROOTS[runtime]


def _state_dir(module: str, stage: str, runtime: str = "claude") -> Path:
    return state_root(runtime) / module / stage


def _now() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _load_score(path: Path) -> dict | None:
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def _load_attempts(module: str, stage: str, runtime: str) -> dict:
    p = _state_dir(module, stage, runtime) / "attempts.json"
    if not p.exists():
        return {"stage_attempt": 0, "total_gate_failures": 0}
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return {"stage_attempt": 0, "total_gate_failures": 0}


def _save_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def arbitrate(
    module: str,
    stage: str,
    max_stage_attempts: int,
    max_total: int,
    runtime: str = "claude",
    force: bool = False,
) -> dict:
    """Arbitrate the four-source scores for ``module``/``stage``.

    Per ``docs/governance/scoring/ARBITER-PROTOCOL.md`` §2 rule 1, missing any
    score source is a hard ``gate=fail``.  The legacy ``--force`` bypass is
    **deprecated**: when ``force=True`` the arbiter still computes a composite
    from the available sources for diagnostic purposes, but it **never** emits
    ``gate=pass`` with missing sources.  Callers that need a hard pass must
    supply all four sources.  A forced run records ``force_override: true`` and
    ``forced_missing_source`` in ``reasons`` so the bypass is always auditable.
    """
    state = _state_dir(module, stage, runtime)
    scores_dir = state / "scores"

    # 1. 四源齐全 + schema 校验
    sources_data: dict[str, dict] = {}
    missing: list[str] = []
    invalid: list[tuple[str, list[str]]] = []
    for src in ALL_SOURCES:
        data = _load_score(scores_dir / f"{src}.json")
        if data is None:
            missing.append(src)
            continue
        errs = _validator.validate(data)
        if errs:
            invalid.append((src, errs))
            continue
        sources_data[src] = data

    attempts = _load_attempts(module, stage, runtime)
    # stage_attempt 仅在有完整四源时才递增；缺失源属于外部平台不可用，不消耗配额

    reasons: list[str] = []
    redlines: list[dict] = []
    gate = "pass"

    if missing and not force:
        gate = "fail"
        reasons.append(f"missing_score_source:{','.join(missing)}")
        next_action = "route_to_missing_score_source"
        composite_score = 0
        llm_scores: list[int] = []
    elif missing and force:
        # --force is DEPRECATED for gating.  We still compute a composite from
        # the available sources for diagnostics, but the gate is ALWAYS fail and
        # ``force_override: true`` is recorded so the bypass is auditable.  Per
        # ARBITER-PROTOCOL §6, ``gate=pass`` is the only condition to advance.
        reasons.append(f"forced_missing_source:{','.join(missing)}")
        present_llm = [s for s in LLM_SOURCES if s in sources_data]
        if present_llm:
            all_scores = {src: int(sources_data[src].get("score", 0)) for src in sources_data}
            composite_score = min(all_scores.values())
            llm_scores = [all_scores[s] for s in present_llm]
            # Diagnostics only — these never produce a pass under force.
            if composite_score < _SCORING["composite_pass_threshold"]:
                reasons.append(f"composite_score({composite_score}) < {_SCORING['composite_pass_threshold']}")
            if len(present_llm) >= 2:
                llm_spread = max(llm_scores) - min(llm_scores)
                if llm_spread > _SCORING["llm_spread_max"]:
                    reasons.append(f"score_spread_too_large:{llm_spread}")
            low_conf = [s for s in present_llm if sources_data[s].get("confidence") == "low"]
            if low_conf:
                reasons.append(f"low_confidence_score:{','.join(low_conf)}")
            for src, d in sources_data.items():
                if d.get("redline"):
                    redlines.append({"source": src, "deductions": d.get("deductions", [])})
            if redlines:
                reasons.append("redline_present")
            if "rules" in sources_data and len(present_llm) >= 1:
                rules_score = int(sources_data["rules"].get("score", 0))
                llm_median = int(statistics.median(llm_scores))
                divergence = abs(rules_score - llm_median)
                if divergence > _SCORING["heterogeneous_divergence_max"]:
                    reasons.append(f"heterogeneous_divergence:{divergence}")
        else:
            composite_score = 0
            llm_scores = []
            reasons.append("forced_no_llm_source:无法判定")
        # Force NEVER passes — hard fail with auditable override flag.
        gate = "fail"
        next_action = "route_to_missing_score_source"
        # --force 时仍计入有效 attempt（因为这是主动决策）
        attempts["stage_attempt"] += 1
    elif invalid:
        gate = "fail"
        invalid_sources = ",".join(src for src, _ in invalid)
        reasons.append(f"invalid_score_schema:{invalid_sources}")
        for src, errs in invalid:
            for err in errs[:3]:
                reasons.append(f"invalid_score_schema:{src}:{err}")
        next_action = "route_to_invalid_score_source"
        composite_score = 0
        llm_scores = []
    else:
        # 四源齐全且全部通过 schema 校验 → 消耗一次有效 stage attempt
        attempts["stage_attempt"] += 1
        pass_threshold = _SCORING["composite_pass_threshold"]
        pass_with_risk_min = _SCORING["composite_pass_with_risk_min"]
        spread_max = _SCORING["llm_spread_max"]
        divergence_max = _SCORING["heterogeneous_divergence_max"]

        # 2. 红线
        for src, d in sources_data.items():
            if d.get("redline"):
                redlines.append({"source": src, "deductions": d.get("deductions", [])})
        if redlines:
            gate = "fail"
            reasons.append("redline_present")

        # 3. composite_score
        all_scores = {src: int(sources_data[src].get("score", 0)) for src in ALL_SOURCES}
        composite_score = min(all_scores.values())
        llm_scores = [all_scores[s] for s in LLM_SOURCES]
        if composite_score < pass_threshold:
            reasons.append(f"composite_score({composite_score}) < {pass_threshold}")

        # 4. LLM 置信度
        low_conf = [
            s for s in LLM_SOURCES if sources_data[s].get("confidence") == "low"
        ]
        if low_conf:
            reasons.append(f"low_confidence_score:{','.join(low_conf)}")

        # 5. LLM 分差
        llm_spread = max(llm_scores) - min(llm_scores)
        if llm_spread > spread_max:
            reasons.append(f"score_spread_too_large:{llm_spread}")

        # 6. 异构一致性
        rules_score = all_scores["rules"]
        llm_median = int(statistics.median(llm_scores))
        divergence = abs(rules_score - llm_median)
        if divergence > divergence_max:
            reasons.append(f"heterogeneous_divergence:{divergence}")

        # 7. 裁决：PASS / PASS_WITH_RISK / FAIL
        #    PASS_WITH_RISK 仅在 composite 是唯一问题且 >= pass_with_risk_min 且
        #    对应 Gate 允许时可用。红线、低置信、分差、异构分歧均为 hard fail。
        hard_fail_reasons = [r for r in reasons if not r.startswith("composite_score(")]
        if not redlines and not hard_fail_reasons and composite_score >= pass_threshold:
            gate = "pass"
            reasons = [r for r in reasons if not r.startswith("composite_score(")]
        elif not redlines and not hard_fail_reasons and composite_score >= pass_with_risk_min:
            stage_gate = _SCORING["stage_gate_map"].get(stage)
            no_pwr_gates = _SCORING["no_pass_with_risk_gates"]
            if stage_gate and stage_gate not in no_pwr_gates:
                gate = "pass_with_risk"
                reasons.append(f"pass_with_risk:composite({composite_score}) >= {pass_with_risk_min}, gate={stage_gate}")
            else:
                gate = "fail"
                reasons.append(f"pass_with_risk_not_allowed:gate={stage_gate}")
        else:
            gate = "fail"

    # 路由
    if gate == "pass":
        next_action = (
            "advance_to_next_stage_and_approve_spec"
            if stage == "spec"
            else "advance_to_next_stage"
        )
    elif gate == "pass_with_risk":
        next_action = (
            "advance_to_next_stage_with_risk_register"
        )
    elif missing and not force:
        next_action = "route_to_missing_score_source"
    elif missing and force:
        next_action = "route_to_missing_score_source"
    elif invalid:
        next_action = "route_to_invalid_score_source"
    elif redlines:
        next_action = "route_to_executor_for_repair"
    else:
        # 复合判定优先级
        if any("heterogeneous_divergence" in r for r in reasons):
            next_action = "route_to_meta_arbiter_for_diagnosis"
        elif any("low_confidence_score" in r for r in reasons):
            next_action = "route_to_low_confidence_scorer_for_rerun"
        elif any("score_spread_too_large" in r for r in reasons):
            next_action = "route_to_scorers_for_reconciliation"
        else:
            next_action = "route_to_executor_for_repair"

    # 失败循环边界
    # missing_score_source 是外部平台可用性问题，不消耗失败配额
    if gate == "fail" and not missing:
        attempts["total_gate_failures"] += 1
        if attempts["total_gate_failures"] >= max_total:
            next_action = "pipeline_blocked_for_retrospective"
        elif attempts["stage_attempt"] >= max_stage_attempts:
            # 回上一阶段
            idx = STAGE_ORDER.index(stage) if stage in STAGE_ORDER else 0
            if idx > 0:
                next_action = f"route_back_to_{STAGE_ORDER[idx - 1]}"
            else:
                # spec 阶段无上一阶段 → 重写 spec
                next_action = "route_back_to_spec_executor_for_rewrite"

    verdict = {
        "module": module,
        "stage": stage,
        "runtime": runtime,
        "state_root": RUNTIME_STATE_ROOTS[runtime],
        "arbitrated_at": _now(),
        "scores": {
            src: {
                "score": int(sources_data[src].get("score", 0)) if src in sources_data else None,
                "redline": bool(sources_data[src].get("redline", False)) if src in sources_data else None,
                "confidence": sources_data[src].get("confidence") if src in sources_data else None,
            }
            for src in ALL_SOURCES
        },
        "composite_score": composite_score,
        "score_range": (
            {
                "min": min(llm_scores),
                "max": max(llm_scores),
                "spread": max(llm_scores) - min(llm_scores),
            }
            if llm_scores
            else None
        ),
        "heterogeneous_divergence": (
            abs(int(sources_data["rules"]["score"]) - int(statistics.median(llm_scores)))
            if (not missing or force) and not invalid and "rules" in sources_data and llm_scores
            else None
        ),
        "invalid_scores": [
            {"source": src, "errors": errs}
            for src, errs in invalid
        ],
        "redlines": redlines,
        "gate": gate,
        "reasons": reasons,
        "next_action": next_action,
        "attempt": attempts["stage_attempt"],
        "force_override": bool(force and missing),
        "repair_budget": {
            "stage_attempt": attempts["stage_attempt"],
            "total_gate_failures": attempts["total_gate_failures"],
            "max_stage_attempts": max_stage_attempts,
            "max_total_gate_failures": max_total,
        },
        "arbiter_engine": "deterministic-1.0",
        "scoring_thresholds": {
            "composite_pass": _SCORING["composite_pass_threshold"],
            "composite_pass_with_risk_min": _SCORING["composite_pass_with_risk_min"],
            "llm_spread_max": _SCORING["llm_spread_max"],
            "heterogeneous_divergence_max": _SCORING["heterogeneous_divergence_max"],
            "stage_gate": _SCORING["stage_gate_map"].get(stage),
        },
    }

    _save_json(state / "verdict.json", verdict)
    _save_json(state / "attempts.json", attempts)
    return verdict


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("module")
    ap.add_argument("stage", choices=list(STAGE_ORDER))
    ap.add_argument(
        "--runtime",
        choices=sorted(RUNTIME_STATE_ROOTS),
        default=default_runtime(),
        help="状态运行时：claude=.omc，codex=.omx，copilot=.copilot",
    )
    ap.add_argument("--max-stage-attempts", type=int, default=_SCORING["max_stage_attempts"])
    ap.add_argument("--max-total", type=int, default=_SCORING["max_total_gate_failures"])
    ap.add_argument("--force", action="store_true", help="DEPRECATED: 缺源时仍计算 composite 供诊断，但 gate 始终 fail 并标记 force_override。不用于放行。")
    args = ap.parse_args()

    verdict = arbitrate(args.module, args.stage, args.max_stage_attempts, args.max_total, args.runtime, args.force)
    print(json.dumps(verdict, ensure_ascii=False, indent=2))
    print(f"\ngate = {verdict['gate']}  next_action = {verdict['next_action']}", file=sys.stderr)
    return 0 if verdict["gate"] in ("pass", "pass_with_risk") else 1


if __name__ == "__main__":
    sys.exit(main())
