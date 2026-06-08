# TASK-XLIB-008

> Debt Governance：7 类技术债规则、debt score、`make debt`

---

```yaml
task_id: TASK-XLIB-008
module: xlib-standard
scope: "实现 Debt Governance——ARCH/DEP/DOMAIN/DOCS/TEST/IMPL/SEC 7 类技术债规则，debt score 计算，`make debt` 命令"
spec_ref:
  - "module/xlib-standard/SPEC.md#FR-033"
  - "module/xlib-standard/SPEC.md#FR-034"
  - "module/xlib-standard/SPEC.md#FR-035"
  - "module/xlib-standard/SPEC.md#FR-036"
  - "module/xlib-standard/SPEC.md#FR-037"
  - "module/xlib-standard/SPEC.md#FR-038"
  - "module/xlib-standard/SPEC.md#FR-039"
files:
  - "pack/debt-scan.json"
  - "docs/standard/debt-rules.yaml"
  - "Makefile"
acceptance_criteria:
  - "AC-I04: `make debt` 7 类技术债规则全部检查，debt score >= 9.8"
  - "FR-033 WHEN `make debt` 执行 THEN ARCH 类规则被检查"
  - "FR-039 WHEN debt score 计算 THEN 返回 0~10.0 分"
depends_on:
  - "TASK-XLIB-001"
  - "TASK-XLIB-006"
estimated_effort: "4h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| FR-033~039 | 7 类技术债规则（ARCH/DEP/DOMAIN/DOCS/TEST/IMPL/SEC） |
| BR-011 | debt score >= 9.8 阻断发布 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | CI Gate | `make debt` 返回 0 |
| — | Unit | 7 类规则全部被检查 |
| — | Unit | debt score 计算正确 |

## Implementation Plan

### Step 1: 定义 7 类技术债规则
- `docs/standard/debt-rules.yaml`：
  - ARCH：架构违规（分层、依赖方向）
  - DEP：依赖问题（版本、安全漏洞）
  - DOMAIN：领域边界违规
  - DOCS：文档缺失或过期
  - TEST：测试覆盖率不足
  - IMPL：实现质量问题
  - SEC：安全问题

### Step 2: 实现 debt-scan gate
- `pack/debt-scan.json`：技术债扫描 gate
- 加载 debt-rules.yaml
- 执行 7 类规则检查
- 计算 debt score（0~10.0）

### Step 3: 实现 Makefile target
- `make debt`：执行技术债扫描
- 输出 debt score 和违规详情
- score < 9.8 时 exit code != 0

### Step 4: 验证
- `make debt` 返回 0
- 7 类规则全部被检查
- debt score 计算正确

### 风险评估

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| 规则定义不完整 | 中 | 高 | 从上游 analysis/rules.md 提取 |
| score 计算公式不准确 | 中 | 中 | 对照上游 goalcli score 实现 |
