#!/usr/bin/env bash
# outer-metrics-eval.sh
#
# 读取所有 .omc/state/outer-metrics/{module}.json，计算 scorer 评分与 real_quality_index 的相关系数，
# 写入 .omc/state/outer-metrics/correlation.json。
# 按宪法 §14.4 触发 Goodhart 信号。
#
# 严禁由 LLM agent 调用；由 cron / CI 触发。
#
# 依赖：python3

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
METRICS_DIR="$ROOT/.omc/state/outer-metrics"
STATE_DIR="$ROOT/.omc/state/pipeline"
OUTPUT="$METRICS_DIR/correlation.json"

python3 - <<PYEOF
import json, os, glob, math, datetime

METRICS_DIR = "$METRICS_DIR"
STATE_DIR   = "$STATE_DIR"
OUTPUT      = "$OUTPUT"

# Real quality index 公式（与 SCHEMA.md §3 保持一致）
def rqi(m):
    if not m: return None
    def g(k, d=0): return m.get(k) or d
    return (100
      - 5   * g("real_bug_count_30d")
      - 3   * g("rework_commit_count")
      - 100 * g("production_incident_count")
      - 50  * (1 if g("rollback_occurred") else 0)
      - 20  * g("security_advisory_count")
      - 50  * g("test_flakiness_7d", 0) * 10
      - 50  * g("ci_failure_rate_post_merge_7d", 0) * 10
      - 30  * g("developer_override_count"))

# 收集 (module, real_quality, per-platform-min-score, per-stage-min-score)
records = []
for f in sorted(glob.glob(os.path.join(METRICS_DIR, "*.json"))):
    if os.path.basename(f) in ("correlation.json",): continue
    try:
        data = json.load(open(f))
    except Exception:
        continue
    module = data.get("module") or os.path.basename(f).replace(".json","")
    # 取最新一次 snapshot
    snap = None
    if "latest_snapshot" in data: snap = data["latest_snapshot"]
    elif data.get("ship_history"): snap = data["ship_history"][-1]
    if not snap: continue
    outer = snap.get("outer_metrics", {})
    quality = rqi(outer)

    # 读对应模块各阶段 verdict.json
    per_stage = {}
    per_platform = {"claude":[], "codex":[], "copilot":[]}
    stages = ["spec","matrix","tasks","plan","prompt","code"]
    for stage in stages:
        v = os.path.join(STATE_DIR, module, stage, "verdict.json")
        if not os.path.exists(v): continue
        try:
            vd = json.load(open(v))
        except Exception:
            continue
        scores = vd.get("scores", {})
        # scores can be { "claude": {"score": 97}, ... } or { "claude": 97 }
        def s(p):
            sv = scores.get(p)
            if isinstance(sv, dict): return sv.get("score")
            return sv
        per_stage[stage] = vd.get("min") or (min([x for x in [s("claude"),s("codex"),s("copilot")] if x is not None] or [None]))
        for p in per_platform:
            v = s(p)
            if v is not None: per_platform[p].append(v)
    if quality is None: continue
    records.append({
        "module": module,
        "quality": quality,
        "per_stage_min": per_stage,
        "per_platform_avg": {p: (sum(v)/len(v) if v else None) for p,v in per_platform.items()}
    })

def spearman(xs, ys):
    pairs = [(x,y) for x,y in zip(xs,ys) if x is not None and y is not None]
    n = len(pairs)
    if n < 3: return None
    def rank(vals):
        sorted_v = sorted((v,i) for i,v in enumerate(vals))
        r = [0]*len(vals)
        for k,(_,i) in enumerate(sorted_v): r[i] = k+1
        return r
    xs2, ys2 = zip(*pairs)
    rx, ry = rank(list(xs2)), rank(list(ys2))
    d2 = sum((a-b)**2 for a,b in zip(rx,ry))
    return round(1 - (6*d2)/(n*(n*n-1)), 4)

n = len(records)
window = f"last_{n}_modules"

# 每平台相关性：用各模块的"平台平均分" vs quality
by_platform = {}
for p in ["claude","codex","copilot"]:
    xs = [r["per_platform_avg"].get(p) for r in records]
    ys = [r["quality"] for r in records]
    corr = spearman(xs, ys)
    by_platform[p] = {"correlation": corr, "modules_evaluated": n}

# 每阶段相关性
by_stage = {}
for s in ["spec","matrix","tasks","plan","prompt","code"]:
    xs = [r["per_stage_min"].get(s) for r in records]
    ys = [r["quality"] for r in records]
    by_stage[s] = spearman(xs, ys)

# 复合相关性：以"所有阶段 min 的平均"作为 composite_score 代理
composite_xs = []
for r in records:
    vals = [v for v in r["per_stage_min"].values() if v is not None]
    composite_xs.append(sum(vals)/len(vals) if vals else None)
composite_corr = spearman(composite_xs, [r["quality"] for r in records])

# Goodhart 信号与冻结
frozen = []
for p, info in by_platform.items():
    c = info["correlation"]
    if c is not None and c < 0.6 and n >= 5:
        frozen.append(f"platform:{p}")
for s, c in by_stage.items():
    if c is not None and c < 0.5 and n >= 5:
        frozen.append(f"stage:{s}")

# 简化的 Goodhart 信号：composite 平均分上升但 quality 平均下降（需要时序数据，这里占位）
goodhart_signal = False

rsi_rec = None
if frozen:
    rsi_rec = f"触发宪法 §14.3 RSI 流程：冻结 {len(frozen)} 个组件，启动 fork + A/B"

result = {
    "computed_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "window": window,
    "by_platform": by_platform,
    "by_stage": by_stage,
    "composite_score_vs_real_quality": composite_corr,
    "goodhart_signal": goodhart_signal,
    "frozen_components": frozen,
    "rsi_recommendation": rsi_rec,
    "_note": "由 scripts/outer-metrics-eval.sh 写入。LLM agent 严禁修改。"
}

with open(OUTPUT, "w") as f:
    json.dump(result, f, indent=2, ensure_ascii=False)
print(f"✓ 写入 {OUTPUT}")
print(f"  评估模块数: {n}")
print(f"  composite_score vs quality: {composite_corr}")
print(f"  冻结组件: {frozen if frozen else '(无)'}")
if rsi_rec:
    print(f"  ⚠ {rsi_rec}")
PYEOF
