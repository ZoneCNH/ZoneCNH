# treasury 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-07-03
Source: [spec/SPEC.md](../spec/SPEC.md) v0.2.0 | Goal: GOAL-TREASURY-001 | Status: Planned（Production Target）

---

## Goal 到需求

| Goal / SC | FR | BR | AC | TC |
| --------- | -- | -- | -- | -- |
| G-SC-001 子模块独立 C/S | FR-TRY-001, FR-TRY-009, FR-TRY-015 | BR-TRY-001, BR-TRY-004 | AC-TRY-001, AC-TRY-006, AC-TRY-009 | TC-TRY-005, TC-TRY-009 |
| G-SC-002 配置不泄密 | FR-TRY-002 | BR-TRY-008 | AC-TRY-002 | TC-TRY-009 |
| G-SC-003 领域归一化 | FR-TRY-007 | BR-TRY-002 | AC-TRY-004 | TC-TRY-002 |
| G-SC-004 七类介质落地 | FR-TRY-008, FR-TRY-010~014 | BR-TRY-005, BR-TRY-006, BR-TRY-007 | AC-TRY-005 | TC-TRY-003, TC-TRY-004 |
| G-SC-005 同步闭环 | FR-TRY-003~006, FR-TRY-016 | BR-TRY-009, BR-TRY-010 | AC-TRY-003, AC-TRY-008 | TC-TRY-001, TC-TRY-007, TC-TRY-008, TC-TRY-010 |
| G-SC-007 宏观分析补充 | FR-TRY-015, FR-TRY-016 | BR-TRY-009, BR-TRY-010 | AC-TRY-010 | TC-TRY-006, TC-TRY-010 |

---

## §1 功能需求追溯（FR）

| FR | 需求摘要 | AC | TC ID(s) | Task | 状态 |
| -- | -------- | -- | -------- | ---- | ---- |
| FR-TRY-001 | 四子模块 client/server 独立启动 | AC-TRY-001 | TC-TRY-005, TC-TRY-009 | TASK-TRY-001 | Planned |
| FR-TRY-002 | 配置通过共享组件加载且不泄密 | AC-TRY-002 | TC-TRY-009 | TASK-TRY-001 | Planned |
| FR-TRY-003 | 收益率曲线采集 | AC-TRY-003 | TC-TRY-001 | TASK-TRY-001 | Planned |
| FR-TRY-004 | 拍卖数据采集 | AC-TRY-003 | TC-TRY-001 | TASK-TRY-001 | Planned |
| FR-TRY-005 | 财政/债务数据采集（DTS/MTS/Debt/Revenue/FX） | AC-TRY-003 | TC-TRY-001 | TASK-TRY-001 | Planned |
| FR-TRY-006 | TIC 月度采集 | AC-TRY-003 | TC-TRY-001 | TASK-TRY-001 | Planned |
| FR-TRY-007 | `domain_macro` 归一化与时间语义 | AC-TRY-004 | TC-TRY-002 | TASK-TRY-001 | Planned |
| FR-TRY-008 | OSS raw-first | AC-TRY-005 | TC-TRY-004 | TASK-TRY-001 | Planned |
| FR-TRY-009 | NATS ingest/control | AC-TRY-006 | TC-TRY-005 | TASK-TRY-001 | Planned |
| FR-TRY-010 | Postgres metadata/checkpoint/ledger | AC-TRY-005 | TC-TRY-003, TC-TRY-004 | TASK-TRY-001 | Planned |
| FR-TRY-011 | taos 时序写入查询 | AC-TRY-005 | TC-TRY-004 | TASK-TRY-001 | Planned |
| FR-TRY-012 | Kafka durable event | AC-TRY-006 | TC-TRY-004, TC-TRY-005 | TASK-TRY-001 | Planned |
| FR-TRY-013 | ClickHouse 读模型 | AC-TRY-005 | TC-TRY-004 | TASK-TRY-001 | Planned |
| FR-TRY-014 | Redis 缓存/锁/限流 | AC-TRY-005 | TC-TRY-003, TC-TRY-004 | TASK-TRY-001 | Planned |
| FR-TRY-015 | 查询/API/作业控制 | AC-TRY-007, AC-TRY-010 | TC-TRY-006 | TASK-TRY-001 | Planned |
| FR-TRY-016 | 覆盖率审计 + 增量/全量重同步 + 缺口重采 | AC-TRY-008, AC-TRY-010 | TC-TRY-008, TC-TRY-010 | TASK-TRY-001 | Planned |

---

## §2 业务规则追溯（BR）

| BR | 规则摘要 | AC | TC ID(s) | Task | 状态 |
| -- | -------- | -- | -------- | ---- | ---- |
| BR-TRY-001 | 子模块独立 C/S 边界 | AC-TRY-009 | TC-TRY-009 | TASK-TRY-001 | Planned |
| BR-TRY-002 | `available_at` no-lookahead 约束 | AC-TRY-004 | TC-TRY-002 | TASK-TRY-001 | Planned |
| BR-TRY-003 | 写入幂等 | AC-TRY-005 | TC-TRY-003 | TASK-TRY-001 | Planned |
| BR-TRY-004 | NATS/Kafka 分层 | AC-TRY-006 | TC-TRY-005 | TASK-TRY-001 | Planned |
| BR-TRY-005 | checkpoint 先于 completed | AC-TRY-005 | TC-TRY-003 | TASK-TRY-001 | Planned |
| BR-TRY-006 | Redis/ClickHouse 可重建 | AC-TRY-005 | TC-TRY-004 | TASK-TRY-001 | Planned |
| BR-TRY-007 | OSS raw 路径可审计 | AC-TRY-005 | TC-TRY-004 | TASK-TRY-001 | Planned |
| BR-TRY-008 | 下游契约边界 | AC-TRY-002, AC-TRY-009 | TC-TRY-009 | TASK-TRY-001 | Planned |
| BR-TRY-009 | 发布触发优先（ET 16:00 窗口） | AC-TRY-003, AC-TRY-010 | TC-TRY-007 | TASK-TRY-001 | Planned |
| BR-TRY-010 | 历史起点与回拉窗口可审计 | AC-TRY-008, AC-TRY-010 | TC-TRY-008, TC-TRY-010 | TASK-TRY-001 | Planned |

---

## §3 非功能需求追溯（NFR）

| NFR | 类别 | Requirement | Task | 状态 |
| --- | ---- | ----------- | ---- | ---- |
| NFR-TRY-001 | Freshness | 日频 <24h，月频 <48h | TASK-TRY-001 | Planned |
| NFR-TRY-002 | Latency | 增量链路 P95 <10min | TASK-TRY-001 | Planned |
| NFR-TRY-003 | Throughput | 子模块并行 backfill 不互阻 | TASK-TRY-001 | Planned |
| NFR-TRY-004 | Reliability | 失败不推进 checkpoint，可回放 | TASK-TRY-001 | Planned |
| NFR-TRY-005 | Observability | 全链路指标与日志闭合 | TASK-TRY-001 | Planned |
| NFR-TRY-006 | Security | secret redaction 通过 | TASK-TRY-001 | Planned |
| NFR-TRY-007 | Governance | 覆盖率与缺口任务可追溯 | TASK-TRY-001 | Planned |

---

## §4 TC→FR 反向追溯

| TC | 覆盖需求 | 目标命令 |
| -- | -------- | -------- |
| TC-TRY-001 | FR-TRY-003~006 | `go test ./internal/client/... -run Collector` |
| TC-TRY-002 | FR-TRY-007, BR-TRY-002 | `go test ./internal/domain/... -run NoLookahead` |
| TC-TRY-003 | FR-TRY-010, FR-TRY-014, BR-TRY-003, BR-TRY-005 | `go test ./internal/server/... -run Idempotency` |
| TC-TRY-004 | FR-TRY-008, FR-TRY-011~014, BR-TRY-006, BR-TRY-007 | `go test ./internal/integration/... -run StoragePipeline` |
| TC-TRY-005 | FR-TRY-001, FR-TRY-009, FR-TRY-012, BR-TRY-004 | `go test ./internal/integration/... -run BusBoundary` |
| TC-TRY-006 | FR-TRY-015 | `go test ./internal/server/... -run APIContract` |
| TC-TRY-007 | BR-TRY-009 | `go test ./internal/client/... -run Scheduler` |
| TC-TRY-008 | FR-TRY-016, BR-TRY-010 | `go test ./internal/integration/... -run BackfillAnchor` |
| TC-TRY-009 | BR-TRY-001, BR-TRY-008 | `bash scripts/boundary-gates.sh` |
| TC-TRY-010 | FR-TRY-016, NFR-TRY-007 | `go test ./internal/integration/... -run CoverageAudit` |

---

## §5 全局 AC 注册表

| AC | 验收摘要 | 覆盖需求 | 状态 |
| --- | --- | --- | --- |
| AC-TRY-001 | 四子模块独立双服务启动 | FR-TRY-001 | Planned |
| AC-TRY-002 | 配置不泄密 | FR-TRY-002, BR-TRY-008 | Planned |
| AC-TRY-003 | 采集清单覆盖完整 | FR-TRY-003~006, BR-TRY-009 | Planned |
| AC-TRY-004 | no-lookahead 语义正确 | FR-TRY-007, BR-TRY-002 | Planned |
| AC-TRY-005 | raw-first + 多存储链路闭合 | FR-TRY-008, FR-TRY-010~014 | Planned |
| AC-TRY-006 | NATS/Kafka 分层验证 | FR-TRY-009, FR-TRY-012, BR-TRY-004 | Planned |
| AC-TRY-007 | API 契约可用 | FR-TRY-015 | Planned |
| AC-TRY-008 | 覆盖率审计与缺口重采闭环 | FR-TRY-016, BR-TRY-010 | Planned |
| AC-TRY-009 | 边界门禁通过 | BR-TRY-001, BR-TRY-008 | Planned |
| AC-TRY-010 | 宏观分析补充项可用 | FR-TRY-015, FR-TRY-016 | Planned |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 16 | 0 | 0% |
| BR | 10 | 0 | 0% |
| NFR | 7 | 0 | 0% |
| AC | 10 | 0 | 0% |
| TC | 10 | 0 | 0% |
| **合计** | **53** | **0** | **0%** |

> 说明：`treasury` 当前为生产目标规格态，状态从 `Planned` 起步。

---

## §7 变更历史

| 日期 | 变更内容 |
| ---- | -------- |
| 2026-07-03 | 从 Draft 占位矩阵升级为生产目标矩阵，补齐 FR/BR/NFR/AC/TC 与覆盖率口径 |
| 2026-06-29 | 初始 Draft 矩阵（隐含 FR 提取） |
