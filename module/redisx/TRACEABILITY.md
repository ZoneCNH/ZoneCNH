# redisx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-12
Source: module/redisx/SPEC.md

| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
| --- | --- | --- | --- | --- | --- |
| FR-001 | KeyBuilder 与命名空间隔离 | AC-001-1 | TC-001-1 | TASK-REDISX-001 | Planned |
| FR-002 | typed Options、New/Close 与连接生命周期 | AC-002-1 | TC-002-1 | TASK-REDISX-000 | Planned |
| FR-003 | KV Get/Set/Del | AC-003-1 | TC-003-1 | TASK-REDISX-002 | Planned |
| FR-004 | Exists/Expire 与默认 TTL 策略 | AC-004-1 | TC-004-1 | TASK-REDISX-002 | Planned |
| FR-005 | CacheClient cache-aside、null-cache、防击穿 | AC-005-1 | TC-005-1 | TASK-REDISX-003 | Planned |
| FR-006 | Hash/List 最小封装 | AC-006-1 | TC-006-1 | TASK-REDISX-004 | Planned |
| FR-007 | Pub/Sub Publish/Subscribe | AC-007-1 | TC-007-1 | TASK-REDISX-004 | Planned |
| FR-008 | Pipeline 有序批量执行 | AC-008-1 | TC-008-1 | TASK-REDISX-005 | Planned |
| FR-009 | token owner 分布式锁 | AC-009-1 | TC-009-1 | TASK-REDISX-006 | Planned |
| FR-010 | Counter 与 fixed-window RateLimitHelper | AC-010-1 | TC-010-1 | TASK-REDISX-007 | Planned |
| FR-011 | JSON 默认 Codec 与自定义 Codec SPI | AC-011-1 | TC-011-1 | TASK-REDISX-000, TASK-REDISX-003 | Planned |
| FR-012 | Health、pool stats 与观测 hooks | AC-012-1 | TC-012-1 | TASK-REDISX-008, TASK-REDISX-009 | Planned |
| BR-001 | Key namespace/env/service/version/entity/id 不变量 | AC-BR-001 | TC-BR-001 | TASK-REDISX-001 | Planned |
| BR-002 | 配置只通过 typed Options 注入 | AC-BR-002 | TC-BR-002 | TASK-REDISX-001 | Planned |
| BR-003 | 所有网络操作尊重 context | AC-BR-003 | TC-BR-003 | TASK-REDISX-002, TASK-REDISX-004, TASK-REDISX-005, TASK-REDISX-007 | Planned |
| BR-004 | TTL 默认策略、jitter 与无意永不过期防护 | AC-BR-004 | TC-BR-004 | TASK-REDISX-002, TASK-REDISX-003, TASK-REDISX-007 | Planned |
| BR-005 | Lock token owner、TTL、续期与释放校验 | AC-BR-005 | TC-BR-005 | TASK-REDISX-006 | Planned |
| BR-006 | Pipeline 有序、非原子、部分错误可诊断 | AC-BR-006 | TC-BR-006 | TASK-REDISX-005 | Planned |
| BR-007 | 错误分类与敏感信息脱敏 | AC-BR-007 | TC-BR-007 | TASK-REDISX-000, TASK-REDISX-003, TASK-REDISX-006 | Planned |
| BR-008 | 重试/重连/熔断只通过本地 hooks 接入 | AC-BR-008 | TC-BR-008 | TASK-REDISX-008 | Planned |
| BR-009 | 指标命名和低基数标签约束 | AC-BR-009 | TC-BR-009 | TASK-REDISX-008 | Planned |
| BR-010 | 依赖边界：stdlib/kernel/Redis client only | AC-BR-010 | TC-BR-010 | TASK-REDISX-000, TASK-REDISX-008 | Planned |
| NFR-001 | 单元与契约测试覆盖所有公开能力 | AC-NFR-001 | TC-NFR-001 | TASK-REDISX-000 | Planned |
| NFR-002 | 真实 Redis 集成、并发和失败路径测试 | AC-NFR-002 | TC-NFR-002 | TASK-REDISX-009 | Planned |
| NFR-003 | 性能基线与 benchmark 预算 | AC-NFR-003 | TC-NFR-003 | TASK-REDISX-009 | Planned |
| NFR-004 | README、配置参考、发布证据齐全 | AC-NFR-004 | TC-NFR-004 | TASK-REDISX-009 | Planned |
