# TASK-XLIB-010

> 治理协议：下游同步、20 PR 执行链、API 规范

---

```yaml
task_id: TASK-XLIB-010
module: xlib-standard
scope: "实现治理协议——下游同步策略（20 PR 执行链）、API 规范（REST/GraphQL/gRPC 三种接入方式的规范层）和标准变更传播"
spec_ref:
  - "specs/xlib-standard/SPEC.md#FR-004"
  - "specs/xlib-standard/SPEC.md#FR-047"
  - "specs/xlib-standard/SPEC.md#FR-048"
  - "specs/xlib-standard/SPEC.md#FR-049"
  - "specs/xlib-standard/SPEC.md#FR-050"
  - "specs/xlib-standard/SPEC.md#FR-051"
  - "specs/xlib-standard/SPEC.md#FR-052"
files:
  - "docs/standard/governance/downstream-sync.md"
  - "docs/standard/governance/api-spec.md"
  - "pack/downstream-sync.json"
acceptance_criteria:
  - "FR-047 WHEN 下游仓库触发同步 THEN 按依赖顺序执行 20 PR 链"
  - "FR-050 WHEN adoption_status 转换 THEN 通过 governance protocol 验证"
  - "FR-052 WHEN 标准变更 THEN 按依赖顺序同步到下游仓库"
depends_on:
  - "TASK-XLIB-002"
  - "TASK-XLIB-006"
estimated_effort: "6h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| FR-004 | 模块依赖层级模型（领域分层 + 门禁） |
| FR-047 | 下游同步策略 |
| FR-048 | API 规范（REST/GraphQL/gRPC） |
| FR-049 | 标准变更传播 |
| FR-050 | adoption_status 转换验证 |
| FR-051 | governance protocol |
| FR-052 | 20 PR 执行链 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | CI Gate | `downstream-sync-policy` gate 通过 |
| — | Unit | 20 PR 链依赖顺序正确 |
| — | Unit | adoption_status 转换验证通过 |

## Implementation Plan

### Step 1: 定义模块依赖层级
- `governance/downstream-sync.md`：依赖层级模型
  - 门禁 → 基座 L0 → 基座 L1 → 基座 L2 → 数据域 → 分析域/决策域 → 执行域 → 入口
  - 横切层（observex/alertx）可被任意层依赖
  - 反向导入被阻断

### Step 2: 实现下游同步策略
- 20 PR 执行链定义
- 按依赖顺序同步（基座 → 数据域 → 分析域 → 决策域 → 执行域）
- 失败阻断后续同步

### Step 3: 定义 API 规范
- `governance/api-spec.md`：三种接入方式
  - REST：标准 HTTP API
  - GraphQL：查询接口
  - gRPC：高性能接口
- 每种方式的规范层定义

### Step 4: 实现 governance protocol
- adoption_status 转换验证
- 标准变更传播机制
- 下游同步失败处理

### Step 5: 验证
- `downstream-sync-policy` gate 通过
- 20 PR 链依赖顺序正确
- adoption_status 转换验证通过

### 风险评估

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| 依赖层级定义不准确 | 中 | 高 | 从上游 ARCHITECTURE.md 提取 |
| 20 PR 链实现复杂 | 高 | 中 | 分阶段实现，先核心后扩展 |
