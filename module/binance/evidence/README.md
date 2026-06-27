# module/binance evidence

模块级交付证据。Gate 级 Evidence Bundle 归属 `.config/goal/evidence/`。

## 当前证据

| Evidence | Task | Status | Date |
|----------|------|--------|------|
| A10-FR024-HOT-RELOAD-EVAL.md | FR-024 Runtime Config Hot Reload | Partial | 2026-06 |
| 2026-06-27/test/worker-a-runtime-evidence.md | GitHub #1269/#1277/#1278/#1279 local runtime evidence | Partial / Evidence Pending | 2026-06-27 |
| 2026-06-27/test/worker-b-observability-evidence.md | GitHub #1270/#1271/#1272/#1275 local observability/control-plane evidence | Partial / Evidence Pending | 2026-06-27 |
| 2026-06-27/test/worker-c-live-evidence-summary.md | GitHub #1273/#1274/#1276 external-dependency evidence summary | Partial / Evidence Pending | 2026-06-27 |
| 2026-06-27/review/issue-alignment-20260627.md | GitHub #1093 and #1268-#1279 tracker synchronization ledger | Tracker Open / Evidence Pending | 2026-06-27 |
| 2026-06-27/review/ISSUE-BLOCKERS-1268-1279.md | GitHub #1268-#1279 / Beads `ZoneCNH-xzcr*` Evidence-Done blocker ledger | Tracker Open / Evidence Pending | 2026-06-27 |
| 2026-06-27/review/issue-closure-10-pass-audit.md | Ten-pass tracker state and wording consistency audit | PASS / Tracker Open / Evidence Pending | 2026-06-27 |

## 证据模板

```text
Evidence ID:     EVID-xxx
Task ID:         TASK-xxx
Test ID:         TEST-xxx
Goal ID:         GOAL-xxx
Date:            YYYY-MM-DD
Status:          PASS / FAIL / PARTIAL
Files Changed:   [文件清单]
Commands Run:    [执行的命令]
Results:         [执行结果]
Requirement Proof: [对应需求证明]
Known Limitations: [已知限制]
```

规范参考：`docs/goal/13-runtime-engine.md` §4
