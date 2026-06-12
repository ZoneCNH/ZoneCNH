# TASK-CONFIGX-004

> 环境变量覆盖：前缀匹配、类型转换、key 映射

---

```yaml
task_id: TASK-CONFIGX-004
module: configx
scope: "实现 WithEnvOverride(prefix)，将环境变量映射为配置键并覆盖"
spec_ref:
  - "module/configx/SPEC.md#SPEC.md#FR-002"
  - "module/configx/SPEC.md#SPEC.md#BR-004"
files:
  - "env.go"
  - "env_test.go"
acceptance_criteria:
  - "前缀匹配的环境变量覆盖对应配置键"
  - "环境变量值类型与 schema 不匹配时返回类型转换错误"
  - "APP_DATA_MARKET_SYMBOL → data.market.symbol 映射正确"
depends_on:
  - "TASK-CONFIGX-003"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| SPEC.md#FR-002 | WithEnvOverride：前缀匹配覆盖，类型不匹配返回错误 | 2 个 WHEN/THEN 场景 |
| SPEC.md#BR-004 | 环境变量覆盖使用前缀 + 下划线 | `APP_DATA_MARKET_SYMBOL` → `data.market.symbol` |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-001 | Unit | 文件 + 环境变量覆盖：环境变量值优先 |
| — | Unit | 前缀过滤：不匹配前缀的环境变量被忽略 |
| — | Unit | 下划线转点分：`APP_A_B_C` → `a.b.c` |
| — | Unit | 类型转换失败：返回 ErrTypeMismatch |
| — | Unit | 空环境变量值：视为空值（非未设置） |

## Non-scope

- 不做配置文件解析（→ TASK-002）
- 不做配置合并（→ TASK-003）
- 不做 schema 校验（→ TASK-005）

## Implementation Notes

- 遍历 `os.Environ()`，过滤前缀匹配的环境变量
- 去掉前缀和第一个下划线，剩余部分 `_` → `.` 转换为点分路径
- 类型转换：string→int、string→bool、string→duration
- 转换失败时返回 ErrTypeMismatch

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `parseEnvVars(prefix)`：遍历 os.Environ，过滤前缀，转换为 map | `env.go` | `go test ./... -run TestParseEnv` 通过 |
| 2 | 实现 key 映射：去掉前缀，`_` → `.` | `env.go` | `go test ./... -run TestEnvKeyMapping` 通过 |
| 3 | 实现类型转换：根据 schema 类型将 string 值转为对应类型 | `env.go` | `go test ./... -run TestEnvTypeConvert` 通过 |
| 4 | 实现 `WithEnvOverride(prefix)` 方法 | `env.go` | TC-001 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 环境变量 key 映射歧义 | Medium | Medium | 统一转小写，`_` 严格分隔 |
| 类型转换遗漏 | Low | Medium | 对照 schema 定义逐一实现 |
