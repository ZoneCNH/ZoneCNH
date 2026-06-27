#!/usr/bin/env python3
"""管线健康度仪表盘生成器。

读取 .foundationx/status/index.json（成熟度事实）和
.omc/state/pipeline/（阶段评分数据），生成 Markdown 仪表盘。

用法:
  python3 scripts/pipeline-dashboard.py [--out docs/workflow/DASHBOARD.md]
"""

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FOUNDATIONX = ROOT / ".foundationx/status/index.json"
PIPELINE = ROOT / ".omc/state/pipeline"
STAGES = ["spec", "matrix", "tasks", "plan", "prompt", "code"]
MATURITY_DIMS = ["spec", "impl", "release", "live", "ci", "adopt", "soak", "factory"]


def load_foundationx() -> dict:
    if not FOUNDATIONX.exists():
        return {}
    return json.loads(FOUNDATIONX.read_text())


def load_pipeline() -> dict[str, dict]:
    data = {}
    if not PIPELINE.exists():
        return data
    for d in sorted(PIPELINE.iterdir()):
        if not d.is_dir():
            continue
        mod = d.name
        stages_data = {}
        for stage in STAGES:
            sd = d / stage
            scores_dir = sd / "scores"
            verdict_file = sd / "verdict.json"
            scores = list(scores_dir.glob("*.json")) if scores_dir.exists() else []
            verdict = None
            if verdict_file.exists():
                try:
                    v = json.loads(verdict_file.read_text())
                    verdict = v.get("gate")
                except Exception:
                    pass
            stages_data[stage] = {
                "scores": len(scores),
                "verdict": verdict,
            }
        data[mod] = stages_data
    return data


def bar(ratio: float, width: int = 10) -> str:
    filled = int(ratio * width)
    empty = width - filled
    if ratio >= 1:
        return "█" * filled
    elif ratio >= 0.5:
        return "▓" * filled + "░" * empty
    elif ratio > 0:
        return "▒" * filled + "░" * empty
    return "░" * width


def verdict_icon(v: str | None) -> str:
    if v == "pass":
        return "✅"
    if v == "fail":
        return "❌"
    return "⬜"


def normalize_name(name: str) -> str:
    """Normalize module names: kebab→snake_case for cross-source matching."""
    return name.replace("-", "_")


def generate(fx: dict, pl: dict) -> str:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    modules_fx_raw = fx.get("modules", {})
    # Normalize foundationx keys to snake_case
    modules_fx = {normalize_name(k): v for k, v in modules_fx_raw.items()}
    summary = fx.get("summary", {})

    # Merge data (normalize pipeline keys too, though they should already be snake_case)
    pl_normalized = {normalize_name(k): v for k, v in pl.items()}
    all_modules = sorted(set(list(modules_fx.keys()) + list(pl_normalized.keys())))

    # Summary stats
    total = len(all_modules)
    fx_total = len(modules_fx)
    pl_total = len([m for m in pl_normalized if any(
        pl_normalized[m][s]["scores"] > 0 for s in STAGES
    )])
    full_pipeline = len([m for m in pl_normalized if all(
        pl_normalized[m][s]["verdict"] for s in STAGES if s in pl_normalized[m]
    )])

    lines = []
    lines.append("# 管线健康度仪表盘")
    lines.append("")
    lines.append(f"> 生成时间: {now}")
    lines.append(f"> 数据源: `.foundationx/status/index.json` ({fx_total} 模块) + `.omc/state/pipeline/` ({pl_total} 有评分数据)")
    lines.append("")
    lines.append("## 总览")
    lines.append("")
    lines.append(f"| 指标 | 值 |")
    lines.append(f"|------|----|")
    lines.append(f"| FoundationX 注册模块 | {fx_total} |")
    lines.append(f"| Pipeline 有评分数据 | {pl_total} |")
    lines.append(f"| Pipeline 全 6 阶段仲裁 | {full_pipeline} |")
    lines.append(f"| FoundationX factory 达标 | {summary.get('factory_ready', summary.get('factory_grade', 'N/A'))} |")
    lines.append("")

    # Maturity summary
    lines.append("## FoundationX 成熟度分布")
    lines.append("")
    # Count per dimension
    dim_counts = {d: 0 for d in MATURITY_DIMS}
    for m in modules_fx.values():
        for d in MATURITY_DIMS:
            if m.get(d) is True:
                dim_counts[d] += 1
    lines.append("| 维度 | 达标模块 | 比例 |")
    lines.append("|------|---------|------|")
    for d in MATURITY_DIMS:
        count = dim_counts[d]
        ratio = count / fx_total if fx_total else 0
        lines.append(f"| {d} | {count}/{fx_total} | {bar(ratio, 15)} {ratio:.0%} |")
    lines.append("")

    # Per-module detail
    lines.append("## 模块管线进度")
    lines.append("")
    lines.append("| 模块 | Maturity | Pipeline 进度 | 仲裁 |")
    lines.append("|------|----------|-------------|------|")

    for mod in all_modules:
        fx_m = modules_fx.get(mod, {})
        pl_m = pl_normalized.get(mod, {})

        # Maturity: count True dims
        mat_count = sum(1 for d in MATURITY_DIMS if fx_m.get(d) is True)
        mat_total = len(MATURITY_DIMS)
        mat_str = f"{bar(mat_count/mat_total, 6)} {mat_count}/{mat_total}"
        if fx_m.get("factory"):
            mat_str += " 🏭"

        # Pipeline: stages with scores > 0
        stage_icons = []
        for s in STAGES:
            sd = pl_m.get(s, {})
            sc = sd.get("scores", 0)
            if sc >= 4:
                stage_icons.append("🟢")
            elif sc >= 2:
                stage_icons.append("🟡")
            elif sc > 0:
                stage_icons.append("🔴")
            else:
                stage_icons.append("⬜")
        pl_str = "".join(stage_icons) + f" SMTaPlPrC"

        # Verdict count
        v_count = sum(1 for s in STAGES if pl_m.get(s, {}).get("verdict") == "pass")
        v_total = sum(1 for s in STAGES if pl_m.get(s, {}).get("verdict") is not None)
        arb_str = f"{v_count}/{v_total} pass" if v_total else "—"

        lines.append(f"| {mod} | {mat_str} | {pl_str} | {arb_str} |")

    lines.append("")
    lines.append("> **图例**: 🟢 四源齐全 🔴 部分 🟡 2源 ⬜ 无 | 🏭 Factory 达标")
    lines.append("")
    lines.append("---")
    lines.append(f"*自动生成于 {now}，数据源更新频率：随 CI pipeline 运行*")
    return "\n".join(lines)


def main():
    import argparse
    ap = argparse.ArgumentParser(description="管线健康度仪表盘")
    ap.add_argument("--out", default="docs/workflow/DASHBOARD.md", help="输出路径")
    args = ap.parse_args()

    fx = load_foundationx()
    pl = load_pipeline()
    md = generate(fx, pl)

    out = ROOT / args.out
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(md)
    print(f"✅ {out.relative_to(ROOT)} ({len(md.splitlines())} lines)")
    print(md[:500])


if __name__ == "__main__":
    main()
