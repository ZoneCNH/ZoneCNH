# eastmoney 需求追溯矩阵

Last-Updated: 2026-07-04  
Source: [spec/SPEC.md](../spec/SPEC.md) | Goal: GOAL-EASTMONEY-001 | Status: Planned (Production Target)

## FR 追溯

| FR | 摘要 | AC | 状态 |
| -- | ---- | -- | ---- |
| FR-001 | 双服务启动与健康检查 | AC-001 | Planned |
| FR-002 | 配置映射且不泄密 | AC-002 | Planned |
| FR-003 | 采集范围完整覆盖（CMD/GMD/IED） | AC-006 | Planned |
| FR-004 | OSS first | AC-003 | Planned |
| FR-005 | `domain_macro` 归一化 + 三时间 | AC-005 | Planned |
| FR-006 | `taos` 时序写入与查询 | AC-003 | Planned |
| FR-007 | `postgres` 控制面写入 | AC-003 | Planned |
| FR-008 | `Redis` 缓存/锁/限流 | AC-003 | Planned |
| FR-009 | Kafka durable event | AC-003 | Planned |
| FR-010 | NATS handoff/control | AC-003 | Planned |
| FR-011 | `clickhouse` 分析读模型 | AC-003 | Planned |
| FR-012 | 增量同步 + 修订回拉 | AC-004 | Planned |
| FR-013 | 历史同步起点与回补 | AC-004 | Planned |
| FR-014 | 边界门禁 | AC-005 | Planned |
| FR-015 | 动态页面受控采集（API/XHR/headless） | AC-007 | Planned |
| FR-016 | 口径标准化（频率/时区/同比环比/季调） | AC-007 | Planned |
| FR-017 | 深度一致性检查与证据沉淀 | AC-008 | Planned |

## BR 追溯

| BR | 规则摘要 | AC | 状态 |
| -- | -------- | -- | ---- |
| BR-001 | 对外只输出稳定契约 | AC-005 | Planned |
| BR-002 | 幂等写入 | AC-005 | Planned |
| BR-003 | no-lookahead 判定 | AC-005 | Planned |
| BR-004 | Redis/ClickHouse 可重建 | AC-003 | Planned |
| BR-005 | NATS/Kafka 职责分层 | AC-003 | Planned |
| BR-006 | 动态采集必须可审计与可回放 | AC-007 | Planned |
| BR-007 | 指标必须具备频率与发布口径标签 | AC-007 | Planned |
