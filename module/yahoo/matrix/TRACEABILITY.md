# yahoo 需求追溯矩阵

Last-Updated: 2026-07-04  
Source: [spec/SPEC.md](../spec/SPEC.md) | Goal: GOAL-YAHOO-001 | Status: Planned

## Goal 到需求

| Goal / SC | FR | BR | AC |
| --------- | -- | -- | -- |
| G-SC-001 双服务独立 | FR-001, FR-010, FR-013 | BR-004, BR-007 | AC-001 |
| G-SC-002 配置不泄密 | FR-002 | BR-001 | AC-002 |
| G-SC-003 领域归一化 | FR-005 | BR-001, BR-003 | AC-003 |
| G-SC-004 完整持久化 | FR-004, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011 | BR-002, BR-004, BR-005, BR-006 | AC-004 |
| G-SC-005 下游稳定契约 | FR-013, FR-014 | BR-001, BR-007 | AC-005 |
| G-SC-006 同步与回补闭环 | FR-003, FR-012 | BR-002, BR-005 | AC-006 |

## FR 追溯

| FR | 需求摘要 | AC | 状态 |
| -- | -------- | -- | ---- |
| FR-001 | client/server 独立服务 | AC-001 | Planned |
| FR-002 | 配置映射与 secret 边界 | AC-002 | Planned |
| FR-003 | Yahoo 采集清单覆盖 | AC-006 | Planned |
| FR-004 | raw 优先归档 | AC-004 | Planned |
| FR-005 | `domain_macro` 归一化 | AC-003 | Planned |
| FR-006 | taos 写入 | AC-004 | Planned |
| FR-007 | postgres 控制面写入 | AC-004 | Planned |
| FR-008 | Redis 热缓存/锁/游标 | AC-004 | Planned |
| FR-009 | Kafka durable event | AC-004 | Planned |
| FR-010 | NATS ingest/control | AC-001 | Planned |
| FR-011 | ClickHouse 读模型 | AC-004 | Planned |
| FR-012 | 增量/回补/修订作业闭环 | AC-006 | Planned |
| FR-013 | 查询 API + as-of/no-lookahead | AC-005 | Planned |
| FR-014 | 边界门禁合规 | AC-005 | Planned |

## AC 注册

| AC | 验收摘要 | 覆盖需求 | 状态 |
| --- | --- | --- | --- |
| AC-001 | 双服务与传输分层合规 | FR-001, FR-010 | Planned |
| AC-002 | 配置与 secret 合规 | FR-002 | Planned |
| AC-003 | 领域语义与 no-lookahead 合规 | FR-005 | Planned |
| AC-004 | 多存储 + 事件链路闭合 | FR-004, FR-006, FR-007, FR-008, FR-009, FR-011 | Planned |
| AC-005 | 查询契约与边界门禁稳定 | FR-013, FR-014 | Planned |
| AC-006 | 采集清单/频率/同步/回补闭环达标 | FR-003, FR-012 | Planned |

