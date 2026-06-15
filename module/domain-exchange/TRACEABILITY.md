# domain-exchange Traceability Matrix

| 字段 | 值 |
| --- | --- |
| 模块 | `domain-exchange` |
| 目标版本 | v1.0.0 |
| 状态 | Done |
| 最后更新 | 2026-06-15 |

## 覆盖矩阵

| 需求 | 验收标准 | 测试证据 | 任务 | 状态 |
| --- | --- | --- | --- | --- |
| FR-EXC-001 | AC-EXC-001: SPI 拆分且组合接口清晰 | TC-EXC-001 compile/adoption | TASK-EXC-001 | Done |
| FR-EXC-002 | AC-EXC-002: 请求包含 idempotency/client/venue/instrument | TC-EXC-002 request validation | TASK-EXC-002 | Done |
| FR-EXC-003 | AC-EXC-003: ExchangeError 可分类并支持 retry 判断 | TC-EXC-003 error table tests | TASK-EXC-003 | Done |
| FR-EXC-004 | AC-EXC-004: capability/profile/rate limit 可静态声明 | TC-EXC-004 capability tests | TASK-EXC-004 | Done |
| FR-EXC-005 | AC-EXC-005: Registry 线程安全并支持 fake exchange | TC-EXC-005 race/concurrency | TASK-EXC-005 | Done |
| FR-EXC-006 | AC-EXC-006: MarketReader 返回 `domain-market` 类型 | TC-EXC-006 type boundary scan | TASK-EXC-006 | Done |
| FR-EXC-007 | AC-EXC-007: Order 返回使用 `domainx` 类型或兼容 alias | TC-EXC-007 domainx adoption | TASK-EXC-007 | Done |

## 发布证据

| 证据 | 值 |
| --- | --- |
| GitHub Release | <https://github.com/ZoneCNH/domain-exchange/releases/tag/v1.0.0> |
| Tag target | `9c11c421ef643768690eb45c88f7b89dbda3afc8` |
| 本地验证 | `go test -count=1 ./...` |
| 公开依赖 | `decimalx v1.0.0` / `domain-market v1.0.1` / `domainx v1.0.1` |
| 结果 | 通过 |
