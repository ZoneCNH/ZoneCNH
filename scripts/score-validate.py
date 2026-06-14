#!/usr/bin/env python3
"""
score-validate.py — 校验 scorer 输出 JSON 是否符合 docs/governance/scoring/score.schema.json

任何 scorer agent（LLM 或规则引擎）写入对应运行时 state_root 下的
pipeline/.../scores/*.json 都必须通过本校验，否则 arbiter 拒绝接受。

用法：
  score-validate.py <path-to-score.json> [<path>...]
  score-validate.py --module <m> --stage <s> [--runtime claude|codex|copilot]
退出码：0=全部合法；1=任一文件不合法或缺失
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCHEMA_PATH = ROOT / "docs/governance/scoring/score.schema.json"
RUNTIME_STATE_ROOTS = {
    "claude": ".omc/state/pipeline",
    "codex": ".omx/state/pipeline",
    "copilot": ".copilot/state/pipeline",
}
LLM_SOURCES = ("claude", "codex", "copilot")
ALL_SOURCES = LLM_SOURCES + ("rules",)
STAGES = {"spec", "matrix", "tasks", "plan", "prompt", "code"}
CONFIDENCES = {"high", "medium", "low"}


def default_runtime() -> str:
    runtime = os.environ.get("SPEC_PIPELINE_RUNTIME", "claude").lower()
    if runtime not in RUNTIME_STATE_ROOTS:
        allowed = ", ".join(sorted(RUNTIME_STATE_ROOTS))
        raise SystemExit(f"不支持的 SPEC_PIPELINE_RUNTIME={runtime!r}; 可选: {allowed}")
    return runtime


def state_root(runtime: str) -> Path:
    return ROOT / RUNTIME_STATE_ROOTS[runtime]


def _load_schema() -> dict:
    return json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))


def validate(payload: dict, schema: dict | None = None) -> list[str]:
    """轻量手写校验，避免 jsonschema 依赖。返回错误列表。"""
    errs: list[str] = []

    # Normalize: accept 'platform' as alias for 'source'
    if "source" not in payload and "platform" in payload:
        payload["source"] = payload["platform"]

    required = ["source", "stage", "module", "score", "redline", "confidence", "deductions"]
    for key in required:
        if key not in payload:
            errs.append(f"missing required field: {key}")
    if errs:
        return errs

    if payload["source"] not in ALL_SOURCES:
        errs.append(f"source not in {ALL_SOURCES}: {payload['source']}")
    if payload["stage"] not in STAGES:
        errs.append(f"stage not in {STAGES}: {payload['stage']}")

    if not isinstance(payload["module"], str) or not payload["module"]:
        errs.append("module must be non-empty string")

    score = payload["score"]
    if not isinstance(score, int) or isinstance(score, bool) or not (0 <= score <= 100):
        errs.append(f"score must be int in [0,100], got {score!r}")

    if not isinstance(payload["redline"], bool):
        errs.append(f"redline must be bool, got {type(payload['redline']).__name__}")

    if payload["confidence"] not in CONFIDENCES:
        errs.append(f"confidence not in {CONFIDENCES}: {payload['confidence']}")

    if not isinstance(payload["deductions"], list):
        errs.append("deductions must be array")
    else:
        for i, d in enumerate(payload["deductions"]):
            if not isinstance(d, dict):
                errs.append(f"deductions[{i}] must be object")
                continue
            for k in ("rule", "points", "evidence"):
                if k not in d:
                    errs.append(f"deductions[{i}] missing {k}")
            if "points" in d:
                pts = d["points"]
                if not isinstance(pts, int) or isinstance(pts, bool) or pts < 0:
                    errs.append(f"deductions[{i}].points must be non-negative int, got {pts!r}")

    return errs


def validate_file(path: Path) -> list[str]:
    if not path.exists():
        return [f"file not found: {path}"]
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        return [f"invalid JSON: {e}"]
    return validate(payload)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("paths", nargs="*", help="JSON 文件路径")
    ap.add_argument("--module")
    ap.add_argument("--stage", choices=sorted(STAGES))
    ap.add_argument("--runtime", choices=sorted(RUNTIME_STATE_ROOTS), default=default_runtime())
    args = ap.parse_args()

    paths: list[Path] = [Path(p) for p in args.paths]
    if args.module and args.stage:
        scores_dir = state_root(args.runtime) / args.module / args.stage / "scores"
        for src in ALL_SOURCES:
            paths.append(scores_dir / f"{src}.json")

    if not paths:
        ap.error("provide paths or --module/--stage")

    rc = 0
    for p in paths:
        errs = validate_file(p)
        if errs:
            rc = 1
            print(f"✗ {p}", file=sys.stderr)
            for e in errs:
                print(f"  - {e}", file=sys.stderr)
        else:
            print(f"✓ {p}")
    return rc


if __name__ == "__main__":
    sys.exit(main())
