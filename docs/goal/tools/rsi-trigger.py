#!/usr/bin/env python3
"""RSI Scorecard auto-trigger — Phase 5 核心组件。

读取 `.config/goal/eval/scorecard.yaml`，检查各维度和综合分数是否低于阈值。
触发时自动生成 RSI Improvement Proposal（`rsi-proposals/`）。

用法:
  python3 docs/goal/tools/rsi-trigger.py                     # 检查 + 输出报告
  python3 docs/goal/tools/rsi-trigger.py --propose           # 触发时生成提案
  python3 docs/goal/tools/rsi-trigger.py --propose --force   # 强制生成提案（忽略阈值）
  python3 docs/goal/tools/rsi-trigger.py --json              # JSON 输出（CI 集成）
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent.parent.parent
SCORECARD_PATH = ROOT / ".config/goal/eval/scorecard.yaml"
EVAL_DATASET_PATH = ROOT / ".config/goal/eval/eval-dataset.yaml"
PROPOSALS_DIR = ROOT / ".config/goal/eval/rsi-proposals"

DIMENSION_LABELS = {
    "impact": "影响力",
    "risk": "风险",
    "verifiability": "可验证性",
    "maintenance_cost": "维护成本",
    "safety_preservation": "安全保持",
}


@dataclass
class TriggerResult:
    triggered: bool
    composite_score: int
    threshold: int
    dimensions_below: list[str]
    recommendations: list[str]
    proposal_path: str | None = None


def load_yaml(path: Path) -> dict[str, Any]:
    import yaml as _yaml
    with open(path, encoding="utf-8") as fh:
        return _yaml.safe_load(fh)


def check_scorecard(scorecard: dict[str, Any]) -> TriggerResult:
    dims = scorecard.get("dimensions", {})
    composite = scorecard.get("composite", {})
    composite_score = composite.get("score", 0)
    threshold = composite.get("threshold", 15)

    dimensions_below: list[str] = []
    recommendations: list[str] = []

    for key, label in DIMENSION_LABELS.items():
        dim = dims.get(key, {})
        score = dim.get("score", 0)
        target = dim.get("target", 3)
        trend = dim.get("trend", "stable")

        if score <= 2:
            dimensions_below.append(f"{label}({key})={score}/5 (阈值=2)")
            recommendations.append(
                f"{label}: 当前 {score}/5, 目标 {target}/5, 趋势 {trend}"
            )

    triggered = bool(dimensions_below) or composite_score < threshold

    if triggered and not dimensions_below:
        recommendations.append(
            f"综合分数 {composite_score} < 阈值 {threshold}，但各维度均 > 2"
        )

    return TriggerResult(
        triggered=triggered,
        composite_score=composite_score,
        threshold=threshold,
        dimensions_below=dimensions_below,
        recommendations=recommendations,
    )


def load_eval_stats() -> dict[str, Any]:
    if not EVAL_DATASET_PATH.exists():
        return {"total_cases": 0, "pass": 0, "fail": 0}
    data = load_yaml(EVAL_DATASET_PATH)
    stats = data.get("stats", {})
    return {
        "total_cases": stats.get("pass", 0) + stats.get("fail", 0),
        "pass": stats.get("pass", 0),
        "fail": stats.get("fail", 0),
    }


def generate_proposal(
    result: TriggerResult, scorecard: dict[str, Any], eval_stats: dict[str, Any]
) -> str:
    proposals_dir = PROPOSALS_DIR
    proposals_dir.mkdir(parents=True, exist_ok=True)

    ts = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    proposal_file = proposals_dir / f"RSI-PROPOSAL-{ts}.md"

    dims = scorecard.get("dimensions", {})
    dim_table = "\n".join(
        f"| {DIMENSION_LABELS.get(k, k)} | {v.get('score', '?')}/5 | {v.get('target', '?')} | {v.get('trend', '?')} |"
        for k, v in dims.items()
    )

    content = f"""# RSI Improvement Proposal

**提案编号**: RSI-PROP-{ts}
**生成时间**: {datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")}
**触发原因**: {" / ".join(result.dimensions_below) if result.dimensions_below else f"综合分数 {result.composite_score} < 阈值 {result.threshold}"}

---

## Scorecard 当前状态

| 维度 | 分数 | 目标 | 趋势 |
|------|------|------|------|
{dim_table}

**综合分数**: {result.composite_score}/{result.threshold * 5 // 3} (阈值: {result.threshold})

## Eval Dataset 状态

| 指标 | 值 |
|------|-----|
| 总案例数 | {eval_stats.get('total_cases', 0)} |
| 通过 | {eval_stats.get('pass', 0)} |
| 失败 | {eval_stats.get('fail', 0)} |

## 建议改进方向

{chr(10).join(f"{i+1}. {r}" for i, r in enumerate(result.recommendations))}

## R0-R9 Gate 预检

- [ ] R0 Evidence Intake: 改进有事实来源
- [ ] R1 Scope Classification: 改进对象分类正确
- [ ] R2 Protected Asset Check: 未触碰受保护资产
- [ ] R3 Safety Preservation: 不降低现有约束
- [ ] R4 Evaluation Replay: 历史案例可回放
- [ ] R5 Projection Consistency: 投影与 SSOT 一致
- [ ] R6 Approval: 审批状态明确
- [ ] R7 Rollout Scope: 灰度范围可控
- [ ] R8 Rollback: 可回滚
- [ ] R9 Retrospective: 改进效果可衡量

## Human Approval

- [ ] Workflow Owner 审批
- [ ] 验证命令: `bash docs/goal/tools/goal-workflow.sh preflight && python3 docs/goal/tools/rsi-trigger.py`

---

*由 rsi-trigger.py 自动生成，待人工审批后执行*
"""
    proposal_file.write_text(content, encoding="utf-8")
    return str(proposal_file)


def main() -> int:
    parser = argparse.ArgumentParser(description="RSI Scorecard auto-trigger")
    parser.add_argument("--propose", action="store_true", help="触发时生成 RSI Proposal")
    parser.add_argument("--force", action="store_true", help="强制生成提案（忽略阈值）")
    parser.add_argument("--json", action="store_true", help="JSON 输出")
    args = parser.parse_args()

    if not SCORECARD_PATH.exists():
        msg = {"error": "scorecard not found", "path": str(SCORECARD_PATH)}
        if args.json:
            print(json.dumps(msg, ensure_ascii=False))
        else:
            print(f"WARN: Scorecard 不存在: {SCORECARD_PATH}")
        return 1

    scorecard = load_yaml(SCORECARD_PATH)
    eval_stats = load_eval_stats()
    result = check_scorecard(scorecard)

    # 更新 scorecard 中的 triggers 状态
    triggers = scorecard.get("triggers", [])
    active_signals = [t for t in triggers if t.get("status") == "active"]
    if active_signals:
        result.dimensions_below.extend(
            f"信号触发: {s['signal']} ({s.get('description', '')})"
            for s in active_signals
        )
        result.triggered = True

    if args.force:
        result.triggered = True

    if args.json:
        output = {
            "triggered": result.triggered,
            "composite_score": result.composite_score,
            "threshold": result.threshold,
            "dimensions_below": result.dimensions_below,
            "recommendations": result.recommendations,
            "eval_stats": eval_stats,
        }
        if result.triggered and (args.propose or args.force):
            proposal_path = generate_proposal(result, scorecard, eval_stats)
            output["proposal_path"] = proposal_path
        print(json.dumps(output, ensure_ascii=False, indent=2))
    else:
        status = "🔴 触发" if result.triggered else "🟢 正常"
        print(f"RSI Scorecard: {status}")
        print(f"  综合分数: {result.composite_score} (阈值: {result.threshold})")
        for key, label in DIMENSION_LABELS.items():
            dim = scorecard.get("dimensions", {}).get(key, {})
            print(f"  {label}: {dim.get('score', '?')}/5 (目标: {dim.get('target', '?')}, 趋势: {dim.get('trend', '?')})")
        print(f"  Eval Dataset: {eval_stats.get('total_cases', 0)} cases ({eval_stats.get('pass', 0)} pass / {eval_stats.get('fail', 0)} fail)")

        if result.dimensions_below:
            print(f"\n低于阈值维度:")
            for d in result.dimensions_below:
                print(f"  - {d}")

        if result.triggered and (args.propose or args.force):
            proposal_path = generate_proposal(result, scorecard, eval_stats)
            print(f"\n✅ RSI Proposal 已生成: {proposal_path}")
            result.proposal_path = proposal_path
        elif result.triggered:
            print(f"\n⚠️  触发条件满足，使用 --propose 生成 RSI Proposal")

    return 0 if not result.triggered else 2


if __name__ == "__main__":
    sys.exit(main())
