#!/usr/bin/env python3
"""Generate STATUS.md projection tables from .foundationx/status/index.json.

Reads the machine fact source and emits markdown tables that can be
inserted into STATUS.md, replacing manual projection blocks.

Usage:
    python3 scripts/generate-status-projection.py            # print to stdout
    python3 scripts/generate-status-projection.py --summary   # summary only
    python3 scripts/generate-status-projection.py --detail    # detail table only
    python3 scripts/generate-status-projection.py --json      # JSON output

Exit code: 0 on success, 2 on error (missing/malformed source).
"""

import argparse
import json
import sys
from pathlib import Path


def load_status(root):
    status_path = root / ".foundationx" / "status" / "index.json"
    if not status_path.is_file():
        print(f"generate-status-projection: {status_path} not found", file=sys.stderr)
        sys.exit(2)
    with open(status_path, "r", encoding="utf-8") as f:
        return json.load(f)


def fmt_bool(val):
    if val is True:
        return "✅"
    if val is False:
        return "❌"
    return str(val)


def generate_summary(data):
    s = data.get("summary", {})
    total = data.get("total_modules", "?")
    lines = [
        "### 汇总（auto-generated from .foundationx/status/index.json）",
        "",
        f"> 生成时间: {data.get('generated_at', '?')} · 生成器: {data.get('generated_by', '?')}",
        "",
        "| 指标 | 值 | 来源 |",
        "|------|-----|------|",
        f"| 总模块数 | {total} | .foundationx/status/index.json |",
        f"| Spec 完成 | {s.get('spec_complete', '?')}/{total} | summary.spec_complete |",
        f"| 实现完成 | {s.get('impl_complete', '?')}/{total} | summary.impl_complete |",
        f"| Release 已发布 | {s.get('release_published', '?')}/{total} | summary.release_published |",
        f"| 真实集成 (Live) | {s.get('live_integration', '?')} | summary.live_integration |",
        f"| Factory Grade | {s.get('factory_grade', '?')}/{total} | summary.factory_grade |",
        f"| Open Blockers | {s.get('open_blockers', '?')} | summary.open_blockers |",
    ]
    return "\n".join(lines)


def generate_detail(data):
    modules = data.get("modules", {})
    lines = [
        "### 模块明细（auto-generated from .foundationx/status/index.json）",
        "",
        "| 模块 | 层级 | 版本 | SPEC | IMPL | RELEASE | LIVE | CI | ADOPT | SOAK | FACTORY |",
        "|------|------|------|:----:|:----:|:-------:|:----:|:--:|:-----:|:----:|:-------:|",
    ]
    for name in sorted(modules.keys()):
        m = modules[name]
        lines.append(
            f"| {name} | {m.get('layer', '?')} | {m.get('version', '?')} "
            f"| {fmt_bool(m.get('spec'))} | {fmt_bool(m.get('impl'))} "
            f"| {fmt_bool(m.get('release'))} | {fmt_bool(m.get('live'))} "
            f"| {fmt_bool(m.get('ci'))} | {fmt_bool(m.get('adopt'))} "
            f"| {fmt_bool(m.get('soak'))} | {fmt_bool(m.get('factory'))} |"
        )
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Generate STATUS.md projection from .foundationx/status/index.json"
    )
    parser.add_argument("--root", default=None, help="Repository root")
    parser.add_argument("--summary", action="store_true", help="Summary table only")
    parser.add_argument("--detail", action="store_true", help="Detail table only")
    parser.add_argument("--json", dest="as_json", action="store_true", help="JSON output")
    args = parser.parse_args()

    root = Path(args.root).resolve() if args.root else Path(__file__).resolve().parent.parent
    data = load_status(root)

    if args.as_json:
        print(json.dumps(data.get("summary", {}), indent=2, ensure_ascii=False))
        return

    if args.summary and not args.detail:
        print(generate_summary(data))
    elif args.detail and not args.summary:
        print(generate_detail(data))
    else:
        print(generate_summary(data))
        print()
        print(generate_detail(data))


if __name__ == "__main__":
    main()
