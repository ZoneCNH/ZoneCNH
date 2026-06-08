# TASK-XLIB-000

> 基础设施：目录结构、schema 定义、基础配置文件

---

```yaml
task_id: TASK-XLIB-000
module: xlib-standard
scope: "创建标准源目录结构、JSON Schema 定义和基础配置文件"
spec_ref:
  - "module/xlib-standard/SPEC.md#14"
  - "module/xlib-standard/SPEC.md#11"
files:
  - "docs/standard/schema/rule.schema.json"
  - "docs/standard/schema/harness.schema.json"
  - "docs/standard/schema/manifest.schema.json"
  - "docs/standard/schema/goalcli-report.schema.json"
  - "harness.yaml"
acceptance_criteria:
  - "AC-T04: registry.yaml 条目可通过 rule.schema.json 验证"
  - "目录结构符合 SPEC.md §14 定义"
depends_on: []
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| §14 | 目录结构定义 |
| §11 | 配置 schema（harness.yaml / registry.yaml） |
| BR-015 | harness.yaml 为唯一机器可读配置源 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Schema | 所有 schema 文件通过 JSON Schema Draft-07 验证 |
| — | CI Gate | `make registry-validate` 通过 |

## Implementation Plan

### Step 1: 创建目录结构
- 创建 `docs/standard/schema/` 目录
- 创建 `docs/standard/governance/` 目录
- 创建 `docs/adr/` 目录
- 创建 `cmd/goalcli/` 目录
- 创建 `goal-runtime/` 目录
- 创建 `pack/` 目录
- 创建 `template/go/` 目录

### Step 2: 定义 JSON Schema
- `rule.schema.json`：规则条目 schema（id, prefix, category, priority, description, severity）
- `harness.schema.json`：gate 条目 schema（name, type, command, timeout, blocking）
- `manifest.schema.json`：Release Manifest schema（version, gates, score, timestamp）
- `goalcli-report.schema.json`：goalcli JSON 输出 schema

### Step 3: 创建 harness.yaml 骨架
- 66 个 gate 条目的 YAML 结构
- 分为 required_gates（44）、extended_gates（10）、final_gates（6）、goalcli_mva_gates（6）

### Step 4: 验证
- 所有 schema 文件通过 JSON Schema Draft-07 验证
- `make registry-validate` 通过

### 风险评估

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| schema 定义不完整 | 中 | 高 | 从上游 docs/standard/** 提取已有定义 |
| 目录结构与上游不一致 | 低 | 中 | 参照 INDEX.md 上游路径 |
