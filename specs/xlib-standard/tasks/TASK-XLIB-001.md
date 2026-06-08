# TASK-XLIB-001

> 标准源：registry.yaml 419 条规则注册、分类与优先级

---

```yaml
task_id: TASK-XLIB-001
module: xlib-standard
scope: "创建 registry.yaml，注册 419 条规则（RULE-CORE/RULE-HARNESS/RULE-EVIDENCE），含分类、优先级和 P0/P1/P2 标记"
spec_ref:
  - "specs/xlib-standard/SPEC.md#FR-001"
  - "specs/xlib-standard/SPEC.md#FR-002"
  - "specs/xlib-standard/SPEC.md#FR-003"
  - "specs/xlib-standard/SPEC.md#BR-001"
  - "specs/xlib-standard/SPEC.md#BR-002"
files:
  - "docs/standard/registry.yaml"
  - "docs/standard/registry-validate.sh"
acceptance_criteria:
  - "AC-T04: registry.yaml 419 条规则 schema 验证通过"
  - "FR-001 WHEN registry.yaml 被 goalcli 加载 THEN 419 条规则全部有条目"
  - "FR-002 WHEN `make debt` 执行 THEN 7 类规则全部被检查"
  - "FR-003 WHEN 规则按前缀分类查询 THEN 返回正确类别和优先级"
depends_on:
  - "TASK-XLIB-000"
estimated_effort: "4h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| FR-001 | 419 条规则注册表 |
| FR-002 | 7 类技术债扫描规则 |
| FR-003 | 规则分类与优先级 |
| BR-001 | registry.yaml schema 验证 |
| BR-002 | 规则编号唯一性 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | CI Gate | `goalcli registry-validate` 返回 0 |
| — | Unit | 419 条规则无重复编号 |
| — | Unit | P0=119, P1=244, P2=56 分布正确 |

## Implementation Plan

### Step 1: 提取规则清单
- 从上游 `docs/standard/rules.md` 提取全部 419 条规则
- 按前缀分类：RULE-CORE（119 P0）、RULE-HARNESS（244 P1）、RULE-EVIDENCE（56 P2）

### Step 2: 创建 registry.yaml
- 每条规则包含：id, prefix, category, priority, description, severity, source_ref
- 使用 `rule.schema.json` 验证格式
- 确保无重复编号

### Step 3: 实现 registry-validate.sh
- 加载 registry.yaml
- 校验 schema 合规性
- 校验编号唯一性
- 输出验证结果 JSON

### Step 4: 验证
- `goalcli registry-validate` 返回 0
- 419 条规则无重复
- P0/P1/P2 分布正确

### 风险评估

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| 规则清单不完整 | 中 | 高 | 对照上游 docs/standard/rules.md 逐条核对 |
| 规则编号冲突 | 低 | 高 | validate 脚本自动检测重复 |
