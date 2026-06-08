#!/usr/bin/env python3
"""
pipeline.py — 管线驱动器

围绕当前运行时 state_root/pipeline/{module}/{stage}/ 提供：
- status <module>              查看所有阶段评分与 gate 状态
- arbitrate <module> <stage>   运行 rule-scorer + arbiter，返回 gate
- reset <module> [<stage>]     清空状态（小心使用）
- next <module>                返回下一个需要工作的阶段（或 done）

LLM executor 与 scorer 仍由人工或平台 CLI 触发；本脚本只串联
确定性环节（rule-scorer + arbiter）并提供可视化。默认运行时为 Claude `.omc`，
Codex 使用 `.omx`，Copilot 使用 `.copilot`。
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RUNTIME_STATE_ROOTS = {
    "claude": ".omc/state/pipeline",
    "codex": ".omx/state/pipeline",
    "copilot": ".copilot/state/pipeline",
}
STAGES = ("spec", "matrix", "tasks", "plan", "prompt", "code")
LLM_SOURCES = ("claude", "codex", "copilot")
ALL_SOURCES = LLM_SOURCES + ("rules",)


def default_runtime() -> str:
    runtime = os.environ.get("SPEC_PIPELINE_RUNTIME", "claude").lower()
    if runtime not in RUNTIME_STATE_ROOTS:
        allowed = ", ".join(sorted(RUNTIME_STATE_ROOTS))
        raise SystemExit(f"不支持的 SPEC_PIPELINE_RUNTIME={runtime!r}; 可选: {allowed}")
    return runtime


DEFAULT_RUNTIME = default_runtime()


def state_root(runtime: str = DEFAULT_RUNTIME) -> Path:
    return ROOT / RUNTIME_STATE_ROOTS[runtime]


def _stage_dir(module: str, stage: str, runtime: str = DEFAULT_RUNTIME) -> Path:
    return state_root(runtime) / module / stage


def _load_json(p: Path) -> dict | None:
    if not p.exists():
        return None
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return None


def _module_dir(module: str, runtime: str = DEFAULT_RUNTIME) -> Path:
    return state_root(runtime) / module


# ---------- status ----------


def cmd_status(module: str, runtime: str = DEFAULT_RUNTIME) -> int:
    print(f"# Pipeline status: {module}\n")
    module_dir = _module_dir(module, runtime)
    state_label = module_dir.relative_to(ROOT) if module_dir.exists() else "(empty)"
    print(f"Runtime: `{runtime}`")
    print(f"State: `{state_label}`\n")

    rows = []
    for stage in STAGES:
        sd = _stage_dir(module, stage, runtime)
        scores_dir = sd / "scores"
        sources_present = []
        scores = {}
        for src in ALL_SOURCES:
            data = _load_json(scores_dir / f"{src}.json")
            if data:
                sources_present.append(src)
                scores[src] = data.get("score", "?")
        verdict = _load_json(sd / "verdict.json")
        gate = verdict["gate"] if verdict else "-"
        composite = verdict["composite_score"] if verdict else "-"
        next_action = verdict["next_action"] if verdict else "-"
        attempt = verdict["attempt"] if verdict else 0
        rows.append((stage, len(sources_present), composite, gate, attempt, next_action))

    print("| Stage | Sources | Composite | Gate | Attempt | Next Action |")
    print("|-------|---------|-----------|------|---------|-------------|")
    for r in rows:
        print(f"| {r[0]} | {r[1]}/4 | {r[2]} | {r[3]} | {r[4]} | {r[5]} |")
    return 0


# ---------- arbitrate ----------


def cmd_arbitrate(module: str, stage: str, runtime: str = DEFAULT_RUNTIME) -> int:
    print(f"── 运行 rule-scorer: {stage} {module} ({runtime})", file=sys.stderr)
    rc = subprocess.run(
        ["python3", str(ROOT / "scripts/rule-scorer.py"), stage, module, "--runtime", runtime],
        capture_output=True, text=True,
    )
    if rc.returncode != 0:
        print(rc.stderr, file=sys.stderr)
        return rc.returncode
    print("  ✓ rule-scorer 完成", file=sys.stderr)

    print(f"── 运行 arbiter: {stage} {module} ({runtime})", file=sys.stderr)
    rc = subprocess.run(
        ["python3", str(ROOT / "scripts/arbiter.py"), module, stage, "--runtime", runtime],
        text=True,
    )
    return rc.returncode


# ---------- next ----------


def cmd_next(module: str, runtime: str = DEFAULT_RUNTIME) -> int:
    for stage in STAGES:
        v = _load_json(_stage_dir(module, stage, runtime) / "verdict.json")
        if v is None:
            print(stage)
            return 0
        if v["gate"] != "pass":
            print(stage)
            return 0
    print("done")
    return 0


# ---------- reset ----------


def cmd_reset(module: str, stage: str | None, runtime: str = DEFAULT_RUNTIME) -> int:
    target = _stage_dir(module, stage, runtime) if stage else _module_dir(module, runtime)
    if not target.exists():
        print(f"路径不存在: {target}", file=sys.stderr)
        return 1
    confirm = input(f"删除 {target.relative_to(ROOT)} ? [y/N] ").strip().lower()
    if confirm != "y":
        print("取消")
        return 1
    shutil.rmtree(target)
    print(f"✓ 已删除 {target.relative_to(ROOT)}")
    return 0


# ---------- main ----------


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_status = sub.add_parser("status", help="查看模块管线状态")
    p_status.add_argument("module")
    p_status.add_argument("--runtime", choices=sorted(RUNTIME_STATE_ROOTS), default=DEFAULT_RUNTIME)

    p_arb = sub.add_parser("arbitrate", help="运行 rule-scorer + arbiter")
    p_arb.add_argument("module")
    p_arb.add_argument("stage", choices=STAGES)
    p_arb.add_argument("--runtime", choices=sorted(RUNTIME_STATE_ROOTS), default=DEFAULT_RUNTIME)

    p_next = sub.add_parser("next", help="下一个需要工作的阶段")
    p_next.add_argument("module")
    p_next.add_argument("--runtime", choices=sorted(RUNTIME_STATE_ROOTS), default=DEFAULT_RUNTIME)

    p_reset = sub.add_parser("reset", help="清空状态")
    p_reset.add_argument("module")
    p_reset.add_argument("stage", nargs="?", choices=STAGES, default=None)
    p_reset.add_argument("--runtime", choices=sorted(RUNTIME_STATE_ROOTS), default=DEFAULT_RUNTIME)

    args = ap.parse_args()

    if args.cmd == "status":
        return cmd_status(args.module, args.runtime)
    if args.cmd == "arbitrate":
        return cmd_arbitrate(args.module, args.stage, args.runtime)
    if args.cmd == "next":
        return cmd_next(args.module, args.runtime)
    if args.cmd == "reset":
        return cmd_reset(args.module, args.stage, args.runtime)
    return 1


if __name__ == "__main__":
    sys.exit(main())
