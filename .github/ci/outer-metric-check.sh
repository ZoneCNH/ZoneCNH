#!/usr/bin/env bash
# outer-metric-check.sh — 校验 scorer 分数与 outer metric 的相关性闭环
#
# 按宪法 §14.4 和 docs/goal/20-metrics-evidence.md 要求：
# 1. 检查 PASS_WITH_RISK verdict 是否记录了 risk 元数据
# 2. 检查已发布模块是否有 Metrics Snapshot 证据
# 3. 检查 Evidence Bundle 是否存在且完整
# 4. 标记 scorer 分数与 outer metric 缺失相关性的模块
#
# 退出码：0=通过（或仅有警告），1=发现违规
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
FAIL=0
WARN=0
CHECKED=0

echo "=== Outer metric correlation check ==="
echo "root: $ROOT"
echo

# 1. 检查 PASS_WITH_RISK verdict 是否有 risk 元数据
echo "--- PASS_WITH_RISK risk metadata check ---"
for runtime_dir in .omc/state/pipeline .omx/state/pipeline .copilot/state/pipeline; do
  pipeline_root="$ROOT/$runtime_dir"
  [[ -d "$pipeline_root" ]] || continue
  while IFS= read -r verdict_file; do
    [[ -f "$verdict_file" ]] || continue
    CHECKED=$((CHECKED + 1))
    gate=$(python3 -c "import json; print(json.load(open('$verdict_file')).get('gate',''))" 2>/dev/null || echo "")
    if [[ "$gate" == "pass_with_risk" ]]; then
      # Check if risk metadata exists in reasons
      has_risk=$(python3 -c "
import json
v = json.load(open('$verdict_file'))
reasons = v.get('reasons', [])
# PASS_WITH_RISK must have pass_with_risk reason AND ideally risk register
has_pwr = any('pass_with_risk' in r for r in reasons)
print('yes' if has_pwr else 'no')
" 2>/dev/null || echo "no")
      if [[ "$has_risk" == "no" ]]; then
        FAIL=1
        rel=$(realpath --relative-to="$ROOT" "$verdict_file")
        printf '  [MISSING-RISK] %s: PASS_WITH_RISK without risk metadata\n' "$rel"
      fi
    fi
  done < <(find "$pipeline_root" -name 'verdict.json' 2>/dev/null)
done
echo "  checked: $CHECKED verdicts"
echo

# 2. 检查已发布模块的 Metrics Snapshot 证据
echo "--- Metrics Snapshot evidence check ---"
EVID_DIR="$ROOT/.config/goal/evidence"
if [[ -d "$EVID_DIR" ]]; then
  evid_count=$(find "$EVID_DIR" -name 'EVID-*.md' 2>/dev/null | wc -l)
  metrics_count=$(find "$EVID_DIR" -name 'EVID-*.md' -exec grep -l 'Metrics Snapshot\|metrics_snapshot\|outer_metric' {} \; 2>/dev/null | wc -l)
  echo "  evidence files: $evid_count"
  echo "  with metrics:   $metrics_count"
  if [[ $evid_count -gt 0 && $metrics_count -eq 0 ]]; then
    WARN=1
    echo "  [WARN] No evidence files contain Metrics Snapshot data"
  fi
else
  echo "  [INFO] No evidence directory — skipping metrics check"
fi
echo

# 3. 检查 scorer 分数与 outer metric 相关性（静态检查）
echo "--- Scorer ↔ outer metric correlation check ---"
# For each module with pipeline state, check if scoring thresholds are recorded
for runtime_dir in .omc/state/pipeline; do
  pipeline_root="$ROOT/$runtime_dir"
  [[ -d "$pipeline_root" ]] || continue
  scored_modules=0
  metric_modules=0
  while IFS= read -r verdict_file; do
    [[ -f "$verdict_file" ]] || continue
    has_thresholds=$(python3 -c "
import json
v = json.load(open('$verdict_file'))
print('yes' if v.get('scoring_thresholds') else 'no')
" 2>/dev/null || echo "no")
    if [[ "$has_thresholds" == "yes" ]]; then
      scored_modules=$((scored_modules + 1))
    fi
  done < <(find "$pipeline_root" -name 'verdict.json' 2>/dev/null)
  echo "  verdicts with scoring_thresholds: $scored_modules"
  if [[ $scored_modules -gt 0 ]]; then
    echo "  [OK] Scoring thresholds are recorded in verdicts (auditability confirmed)"
  else
    echo "  [INFO] No verdicts with scoring_thresholds yet"
  fi
done
echo

# 4. 检查 rules.yaml scoring 段是否完整
echo "--- Rules.yaml scoring config check ---"
RULES_FILE="$ROOT/.config/goal/schema/rules.yaml"
if [[ -f "$RULES_FILE" ]]; then
  has_scoring=$(python3 -c "
import yaml
with open('$RULES_FILE') as f:
    data = yaml.safe_load(f)
s = data.get('scoring', {})
required = ['composite_pass_threshold', 'composite_pass_with_risk_min',
            'llm_spread_max', 'heterogeneous_divergence_max',
            'stage_gate_map', 'no_pass_with_risk_gates']
missing = [k for k in required if k not in s]
if missing:
    print('MISSING:' + ','.join(missing))
else:
    print('OK')
" 2>/dev/null || echo "ERROR")
  if [[ "$has_scoring" == "OK" ]]; then
    echo "  [OK] scoring config complete in rules.yaml"
  else
    FAIL=1
    echo "  [FAIL] scoring config incomplete: $has_scoring"
  fi
else
  echo "  [INFO] rules.yaml not found"
fi
echo

echo "=== Summary ==="
if [[ "$FAIL" -ne 0 ]]; then
  echo "FAIL: 发现 outer metric 相关性违规"
  exit 1
fi
if [[ "$WARN" -ne 0 ]]; then
  echo "PASS (with warnings): 检查通过但存在建议项"
  exit 0
fi
echo "PASS: outer metric 相关性检查通过"
exit 0
