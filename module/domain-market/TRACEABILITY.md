# domain-market Traceability Matrix

| 字段 | 值 |
| --- | --- |
| 模块 | `domain-market` |
| 目标版本 | v1.0.0 |
| 状态 | Done |
| 最后更新 | 2026-06-15 |

## 覆盖矩阵

| 需求 | 验收标准 | 测试证据 | 任务 | 状态 |
| --- | --- | --- | --- | --- |
| FR-MKT-001 | AC-MKT-001: public 金融字段采用 `decimalx.Decimal` | TC-MKT-001 API/static scan | TASK-MKT-001 | Done |
| FR-MKT-002 | AC-MKT-002: 核心行情对象验证 symbol/time/price/qty | TC-MKT-002 validator table tests | TASK-MKT-002 | Done |
| FR-MKT-003 | AC-MKT-003: quality gate fail-closed | TC-MKT-003 dirty/stale/time-invalid cases | TASK-MKT-003 | Done |
| FR-MKT-004 | AC-MKT-004: Instrument 精度与状态语义稳定 | TC-MKT-004 instrument invariant tests | TASK-MKT-004 | Done |
| FR-MKT-005 | AC-MKT-005: 衍生品指标具备来源与时间语义 | TC-MKT-005 derivative data cases | TASK-MKT-005 | Done |
| FR-MKT-006 | AC-MKT-006: provider contract 不泄漏 transport/vendor DTO | TC-MKT-006 static boundary scan | TASK-MKT-006 | Done |
| FR-MKT-007 | AC-MKT-007: 订单枚举与 `domainx` 单一归属 | TC-MKT-007 compile/adoption check | TASK-MKT-007 | Done |

## 发布证据

| 证据 | 值 |
| --- | --- |
| GitHub Release | <https://github.com/ZoneCNH/domain-market/releases/tag/v1.0.1> |
| Tag target | `7bf9d6c311ba9bff9241440fcf1337691d80d02c` |
| 本地验证 | `go test -count=1 ./...` |
| 结果 | 通过 |
