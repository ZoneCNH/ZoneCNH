# TASK-XLIB-007

> Evidence Runtime：append-only ledger、Release Manifest、完整性检查

---

```yaml
task_id: TASK-XLIB-007
module: xlib-standard
scope: "实现 Evidence Runtime——append-only ledger.jsonl、Release Manifest schema、完整性检查和 evidence protocol"
spec_ref:
  - "specs/xlib-standard/SPEC.md#FR-026"
  - "specs/xlib-standard/SPEC.md#FR-027"
  - "specs/xlib-standard/SPEC.md#FR-028"
  - "specs/xlib-standard/SPEC.md#FR-029"
  - "specs/xlib-standard/SPEC.md#FR-030"
  - "specs/xlib-standard/SPEC.md#FR-031"
  - "specs/xlib-standard/SPEC.md#FR-032"
files:
  - "docs/standard/schema/manifest.schema.json"
  - "docs/standard/schema/ledger-entry.schema.json"
  - "pack/evidence-replay.json"
  - "pack/evidence-integrity.json"
  - "pack/release-final-check.json"
acceptance_criteria:
  - "AC-R01: Evidence Ledger append-only，篡改检测有效"
  - "AC-R04: dirty workspace 阻断 release"
  - "AC-R05: DONE with evidence 格式强制"
  - "AC-R06: skipped gate 不得记为 passed"
  - "xlib-TC-012: release-final-check 缺失 manifest 必填字段时退出码 1"
depends_on:
  - "TASK-XLIB-006"
estimated_effort: "6h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| FR-026 | append-only Evidence Ledger |
| FR-027 | Release Manifest schema |
| FR-028 | DONE with evidence 格式 |
| FR-029 | evidence protocol |
| FR-030 | skipped gate 不记为 passed |
| FR-031 | dirty workspace 阻断 release |
| FR-032 | 失败 Evidence 不得删除 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| xlib-TC-012 | TL6 Release | 缺失 manifest 必填字段时退出码 1 |
| — | Unit | append-only 验证（篡改检测） |
| — | Unit | dirty workspace 阻断 release |

## Implementation Plan

### Step 1: 定义 Evidence Schema
- `manifest.schema.json`：Release Manifest（version, gates[], score, timestamp, commit_sha）
- `ledger-entry.schema.json`：Ledger 条目（gate, status, timestamp, evidence_ref, duration）

### Step 2: 实现 evidence-replay gate
- `pack/evidence-replay.json`：重放 Evidence Ledger
- 验证 append-only 语义
- 检测篡改（hash 链验证）

### Step 3: 实现 evidence-integrity gate
- `pack/evidence-integrity.json`：完整性检查
- 验证所有 gate 结果已记录
- 验证 skipped gate 未记为 passed
- 验证失败 Evidence 未被删除

### Step 4: 实现 release-final-check gate
- `pack/release-final-check.json`：发布前最终检查
- 验证 Release Manifest 必填字段完整
- 验证 dirty workspace 阻断
- 验证 Release Scorecard >= 9.8

### Step 5: 验证
- xlib-TC-012 通过
- append-only 验证通过
- dirty workspace 阻断 release

### 风险评估

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| Schema 字段遗漏 | 中 | 高 | 从上游 analysis/runtime.md §4 提取 |
| hash 链实现复杂 | 中 | 中 | 使用 SHA-256 简化实现 |
