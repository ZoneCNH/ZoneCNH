#!/usr/bin/env python3
"""
projection-sync.py — 投影层与事实层一致性核查工具

S-7 反向工作流修复的第一步雏形：从 `.foundationx/status/index.json`（机器事实源）
投影出"应当呈现的 STATUS 数字"，并与 STATUS.md 中手工块对比，报告漂移。

设计目标：
1. 单向 READ：只读事实源 + 手工投影文档，不修改任何文件。
2. 显式 diff：报告每个手工数字与机器投影值的差异。
3. CI 可消费：以 stdout 文本 + exit code 表达结果（0=一致 / 1=漂移）。
4. 不替代 audit-status.py：audit 检查跨字段一致性，本脚本检查事实↔投影漂移。

使用方法：
    python3 scripts/projection-sync.py            # 报告 + exit code
    python3 scripts/projection-sync.py --json     # 机器可读 JSON 输出

后续演进路径：
- 阶段二：扩展到业务域模块（需先建业务域事实层）
- 阶段三：从只读 diff 升级为 STATUS.md auto-patch（投影自动写入手工块）
- 阶段四：将 README/ARCHITECTURE 也纳入投影范围

S-7 反向工作流根因：投影层（README/ARCHITECTURE/STATUS）与事实层
（.foundationx/status/index.json）未分离，每次实现变更需手工同步多处，
churn 高。正确做法是投影层从事实层机器生成。
"""

import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
INDEX_PATH = ROOT / ".foundationx" / "status" / "index.json"
STATUS_PATH = ROOT / "STATUS.md"


def load_fact_source() -> dict[str, Any]:
    """读取机器事实源。"""
    return json.loads(INDEX_PATH.read_text(encoding="utf-8"))


def parse_status_dashboard(text: str) -> dict[str, Any]:
    """从 STATUS.md 总览仪表盘提取手工数字。"""
    m = re.search(
        r"组件总数:\s*(\d+)\s+已有:\s*(\d+)\s+已创建:\s*(\d+)\s+平均进度:\s*(\d+)%",
        text,
    )
    if not m:
        return {}
    return {
        "total": int(m.group(1)),
        "existing": int(m.group(2)),
        "created": int(m.group(3)),
        "progress_pct": int(m.group(4)),
    }


def compute_projection(fact: dict[str, Any]) -> dict[str, Any]:
    """从事实源投影 STATUS 应呈现的数字。

    当前阶段仅覆盖 21 个 Foundation 模块。业务域模块缺机器事实源时，
    投影只反映 Foundation 部分，业务域数字仍依赖手工。
    """
    summary = fact.get("summary", {})
    return {
        "foundation_modules": fact.get("total_modules", 0),
        "foundation_spec_complete": summary.get("spec_complete", 0),
        "foundation_impl_complete": summary.get("impl_complete", 0),
        "foundation_release_published": summary.get("release_published", 0),
        "foundation_live_integration": summary.get("live_integration", 0),
        "foundation_factory_grade": summary.get("factory_grade", 0),
        "foundation_open_blockers": summary.get("open_blockers", 0),
    }


def compute_drift(dashboard: dict[str, Any], projection: dict[str, Any]) -> list[dict]:
    """计算手工 vs 机器投影漂移。

    当前阶段：仪表盘"组件总数"是全域计数（73），与 Foundation 21 不直接可比。
    报告区分两类漂移：
      - 直接可比项：Foundation factory/release 等
      - 间接项：全域总数（需业务域事实层建成后才可投影）
    """
    drifts = []

    drifts.append({
        "field": "dashboard.total",
        "manual": dashboard.get("total"),
        "machine": None,
        "status": "PENDING_FACT_SOURCE",
        "note": "全域总数 73 含基座 21 + L2.5 5 + 业务域 47；业务域无事实层",
    })

    drifts.append({
        "field": "foundation.factory_count",
        "manual": None,
        "machine": projection["foundation_factory_grade"],
        "status": "INFO",
        "note": f"Foundation factory-grade={projection['foundation_factory_grade']}/{projection['foundation_modules']}",
    })

    drifts.append({
        "field": "foundation.open_blockers",
        "manual": None,
        "machine": projection["foundation_open_blockers"],
        "status": "INFO",
        "note": f"open_blockers={projection['foundation_open_blockers']} (机器事实)",
    })

    return drifts


def report_text(fact: dict[str, Any], dashboard: dict[str, Any],
                projection: dict[str, Any], drifts: list[dict]) -> str:
    """生成人类可读报告。"""
    lines = []
    lines.append("# Projection Sync Report")
    lines.append("")
    lines.append(f"Fact source: {INDEX_PATH.relative_to(ROOT)}")
    lines.append(f"Fact generated_at: {fact.get('generated_at')}")
    lines.append(f"Projection target: {STATUS_PATH.relative_to(ROOT)}")
    lines.append("")
    lines.append("## STATUS dashboard (manual)")
    for k, v in dashboard.items():
        lines.append(f"  {k}: {v}")
    lines.append("")
    lines.append("## Foundation projection (machine)")
    for k, v in projection.items():
        lines.append(f"  {k}: {v}")
    lines.append("")
    lines.append("## Drift report")
    if not drifts:
        lines.append("  (no drift)")
    for d in drifts:
        sym = {
            "OK": "✓",
            "DRIFT": "✗",
            "INFO": "ℹ",
            "PENDING_FACT_SOURCE": "○",
        }.get(d["status"], "?")
        lines.append(f"  {sym} [{d['status']:<20}] {d['field']}")
        if d.get("manual") is not None:
            lines.append(f"     manual:  {d['manual']}")
        if d.get("machine") is not None:
            lines.append(f"     machine: {d['machine']}")
        if d.get("note"):
            lines.append(f"     note:    {d['note']}")
    lines.append("")
    lines.append("## S-7 Roadmap notes")
    lines.append("  Phase 1 (NOW)  : 雏形——只读 diff，业务域 PENDING_FACT_SOURCE")
    lines.append("  Phase 2 (NEXT) : 建立业务域事实层，扩展投影覆盖")
    lines.append("  Phase 3       : 投影自动写入 STATUS 手工块（auto-patch）")
    lines.append("  Phase 4       : README/ARCHITECTURE 同步投影")
    return "\n".join(lines)


def main(argv: list[str]) -> int:
    json_mode = "--json" in argv

    if not INDEX_PATH.exists():
        print(f"ERROR: fact source not found: {INDEX_PATH}", file=sys.stderr)
        return 2
    if not STATUS_PATH.exists():
        print(f"ERROR: projection target not found: {STATUS_PATH}", file=sys.stderr)
        return 2

    fact = load_fact_source()
    status_text = STATUS_PATH.read_text(encoding="utf-8")
    dashboard = parse_status_dashboard(status_text)
    projection = compute_projection(fact)
    drifts = compute_drift(dashboard, projection)

    if json_mode:
        out = {
            "fact_generated_at": fact.get("generated_at"),
            "dashboard": dashboard,
            "projection": projection,
            "drifts": drifts,
        }
        print(json.dumps(out, ensure_ascii=False, indent=2))
    else:
        print(report_text(fact, dashboard, projection, drifts))

    has_drift = any(d["status"] == "DRIFT" for d in drifts)
    return 1 if has_drift else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
