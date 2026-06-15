# decimalx Traceability Matrix

| 字段 | 值 |
| --- | --- |
| 模块 | `decimalx` |
| 目标版本 | v1.0.0 |
| 状态 | Done |
| 最后更新 | 2026-06-15 |

## 覆盖矩阵

| 需求 | 验收标准 | 测试证据 | 任务 | 状态 |
| --- | --- | --- | --- | --- |
| FR-DEC-001 | AC-DEC-001: 系数导出 copy，外部修改不影响原值 | TC-DEC-001 immutability/property | TASK-DEC-001 | Done |
| FR-DEC-002 | AC-DEC-002: whitespace/exponent/非法格式均拒绝 | TC-DEC-002 parse golden/fuzz | TASK-DEC-002 | Done |
| FR-DEC-003 | AC-DEC-003: String/Canonical/FixedString 输出稳定 | TC-DEC-003 formatting golden | TASK-DEC-003 | Done |
| FR-DEC-004 | AC-DEC-004: 精确运算与显式 rounding/context | TC-DEC-004 arithmetic/property | TASK-DEC-004 | Done |
| FR-DEC-005 | AC-DEC-005: JSON 仅使用 quoted decimal string | TC-DEC-005 json marshal/unmarshal | TASK-DEC-005 | Done |
| FR-DEC-006 | AC-DEC-006: SQL scan 拒绝 float | TC-DEC-006 database scan cases | TASK-DEC-006 | Done |
| FR-DEC-007 | AC-DEC-007: Money 跨币种运算 fail-closed | TC-DEC-007 money currency guard | TASK-DEC-007 | Done |
| FR-DEC-008 | AC-DEC-008: typed errors 支持 errors.Is | TC-DEC-008 error compatibility | TASK-DEC-008 | Done |

## 发布证据

| 证据 | 值 |
| --- | --- |
| GitHub Release | <https://github.com/ZoneCNH/decimalx/releases/tag/v1.0.0> |
| Tag target | `fb6080682796ece69c16f396ec37c23f56a50b02` |
| 本地验证 | `GOWORK=off go test -count=1 ./...` |
| 结果 | 通过 |
