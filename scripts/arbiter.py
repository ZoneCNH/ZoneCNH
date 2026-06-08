#!/usr/bin/env python3
"""
arbiter.py — 确定性仲裁器（替代/补充 LLM pipeline-arbiter agent）

严格按 specs/scoring/ARBITER-PROTOCOL.md 算法实现：
1. 四源齐全（claude/codex/copilot/rules）
2. 无红线
3. composite_score = min(claude, codex, copilot, rules) >= 98
4. LLM 置信度全 high
5. LLM 分差 <= 5
6. 异构一致：|rules - median(LLM)| <= 15

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
) -> dict:
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
    attempts["stage_attempt"] += 1
    # 失败时增加 total_gate_failures（计在末尾）

    reasons: list[str] = []
    redlines: list[dict] = []
    gate = "pass"

    if missing:
        gate = "fail"
        reasons.append(f"missing_score_source:{','.join(missing)}")
        next_action = "route_to_missing_score_source"
        composite_score = 0
        llm_scores: list[int] = []
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
        if composite_score < 98:
            gate = "fail"
            reasons.append(f"composite_score({composite_score}) < 98")

        # 4. LLM 置信度
        low_conf = [
            s for s in LLM_SOURCES if sources_data[s].get("confidence") == "low"
        ]
        if low_conf:
            gate = "fail"
            reasons.append(f"low_confidence_score:{','.join(low_conf)}")

        # 5. LLM 分差
        llm_spread = max(llm_scores) - min(llm_scores)
        if llm_spread > 5:
            gate = "fail"
            reasons.append(f"score_spread_too_large:{llm_spread}")

        # 6. 异构一致性
        rules_score = all_scores["rules"]
        llm_median = int(statistics.median(llm_scores))
        divergence = abs(rules_score - llm_median)
        if divergence > 15:
            gate = "fail"
            reasons.append(f"heterogeneous_divergence:{divergence}")

    # 路由
    if gate == "pass":
        next_action = (
            "advance_to_next_stage_and_approve_spec"
            if stage == "spec"
            else "advance_to_next_stage"
        )
    elif missing:
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
    if gate == "fail":
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
            if not missing and not invalid
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
        "repair_budget": {
            "stage_attempt": attempts["stage_attempt"],
            "total_gate_failures": attempts["total_gate_failures"],
            "max_stage_attempts": max_stage_attempts,
            "max_total_gate_failures": max_total,
        },
        "arbiter_engine": "deterministic-1.0",
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
    ap.add_argument("--max-stage-attempts", type=int, default=3)
    ap.add_argument("--max-total", type=int, default=18)
    args = ap.parse_args()

    verdict = arbitrate(args.module, args.stage, args.max_stage_attempts, args.max_total, args.runtime)
    print(json.dumps(verdict, ensure_ascii=False, indent=2))
    print(f"\ngate = {verdict['gate']}  next_action = {verdict['next_action']}", file=sys.stderr)
    return 0 if verdict["gate"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
