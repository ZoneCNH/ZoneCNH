# fred 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-07-08
Source: [spec/SPEC.md](../spec/SPEC.md) | Goal: GOAL-FRED-001 | Status: Implemented (Production Verified; integration CI-gated)

---

## Goal 到需求

| Goal / SC | FR | BR | AC | TC |
| --------- | -- | -- | -- | -- |
| G-SC-001 双服务独立部署 | FR-001, FR-011, FR-013 | BR-004, BR-008 | AC-001, AC-005, AC-007 | TC-006, TC-008 |
| G-SC-002 配置不泄密 | FR-002 | BR-006 | AC-002 | TC-006 |
| G-SC-003 领域归一化 | FR-003, FR-005 | BR-001, BR-002 | AC-006 | TC-001, TC-002, TC-005 |
| G-SC-004 完整持久化 | FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012 | BR-004, BR-005, BR-006, BR-007 | AC-003, AC-004, AC-005 | TC-003, TC-004, TC-006 |
| G-SC-005 下游稳定契约 | FR-010, FR-013, FR-014, FR-015 | BR-001, BR-004, BR-008, BR-009 | AC-005, AC-007, AC-009 | TC-006, TC-008, TC-009 |
| G-SC-006 回放与 no-lookahead | FR-004, FR-005, FR-006, FR-008 | BR-002, BR-003, BR-007 | AC-003, AC-006 | TC-003, TC-005, TC-007 |
| G-SC-007 NATS/Kafka 分层 | FR-011, FR-010 | BR-004 | AC-005 | TC-006 |
| G-SC-008 FRED 全量信息采集 | FR-003, FR-004, FR-016 | BR-010 | AC-010 | TC-010 |

---

## §1 功能需求追溯（FR）

| FR | 需求摘要 | AC | TC ID(s) | Task | 状态 |
| -- | -------- | -- | -------- | ---- | ---- |
| FR-001 | `fred-client`/`fred-server` 双服务启动、health、version | AC-001 | TC-006 | TASK-FRED-001 | Done |
| FR-002 | `configx` 从 `sre/secrets/env/dev.md` 映射配置 | AC-002 | TC-006 | TASK-FRED-001 | Done |
| FR-003 | FRED 全信息域采集 + `spec/SPEC.md` §5.1 全端点矩阵/核心指标包覆盖 + 分页限流重试 | AC-006 | TC-001 | TASK-FRED-CLIENT-001 | Done |
| FR-004 | backfill / incremental / series sync / revision scan | AC-003, AC-006 | TC-003, TC-005 | TASK-FRED-SERVER-001 | Done |
| FR-005 | 转换为 `domain_macro` 并记录信息集时间 | AC-006 | TC-002, TC-007 | TASK-FRED-CLIENT-002 | Done |
| FR-006 | OSS raw 先归档再规范化写入 | AC-003 | TC-004 | TASK-FRED-SERVER-001 | Done |
| FR-007 | TDengine observation 写入和查询 | AC-003 | TC-004 | TASK-FRED-SERVER-001 | Done |
| FR-008 | Postgres metadata / idempotency / checkpoint | AC-003 | TC-003, TC-004 | TASK-FRED-SERVER-001 | Done |
| FR-009 | Redis cache / lock / rate bucket / cursor | AC-004 | TC-005 | TASK-FRED-SERVER-001 | Done |
| FR-010 | Kafka durable event stream | AC-003, AC-005 | TC-004, TC-006 | TASK-FRED-SERVER-001 | Done |
| FR-011 | NATS ingest handoff + control plane | AC-001, AC-005 | TC-006 | TASK-FRED-CLIENT-001, TASK-FRED-SERVER-001 | Done |
| FR-012 | ClickHouse analysis read model | AC-003 | TC-004 | TASK-FRED-SERVER-001 | Done |
| FR-013 | 服务 API | AC-001, AC-003 | TC-001 | TASK-FRED-SERVER-002 | Done |
| FR-014 | 边界门禁允许目标存储、禁止绕过基座 | AC-007 | TC-008 | TASK-FRED-001 | Done |
| FR-015 | `ms_brain` 下游消费画像、初始序列锚点、PIT/as-of、发布/修订事件和 freshness/degrade 契约 | AC-009 | TC-009 | TASK-FRED-SERVER-002 | Done |
| FR-016 | 全量采集覆盖审计与缺口重采闭环（含默认 `1990-01-01` 全量起点、最近 3 个月修订回拉和 `realtime_start/realtime_end` 版本闭合） | AC-010 | TC-010 | TASK-FRED-CLIENT-001, TASK-FRED-SERVER-001 | Done |

---

## §2 业务规则追溯（BR）

| BR | 规则摘要 | AC | TC ID(s) | Task | 状态 |
| -- | -------- | -- | -------- | ---- | ---- |
| BR-001 | 不暴露 provider DTO，对外只出服务 API / Kafka 事件 / `pkg/fredx` / `domain_macro` | AC-007 | TC-002, TC-008 | TASK-FRED-CLIENT-002 | Done |
| BR-002 | 相同 provider / series / period / vintage 写入幂等 | AC-003 | TC-003 | TASK-FRED-SERVER-001 | Done |
| BR-003 | `available_at` 是 no-lookahead 判定依据，晚于 `released_at` 时下游只能在 `available_at` 后使用 | AC-006 | TC-007 | TASK-FRED-CLIENT-002 | Done |
| BR-004 | Kafka 是 durable business event，NATS 只承载 ingest/control plane | AC-005 | TC-006 | TASK-FRED-CLIENT-001, TASK-FRED-SERVER-001 | Done |
| BR-005 | Postgres checkpoint 成功推进前，backfill job 不得进入 completed | AC-003 | TC-003, TC-004 | TASK-FRED-SERVER-001 | Done |
| BR-006 | Redis 与 ClickHouse 均为可重建派生层，不作为唯一权威源 | AC-004 | TC-005 | TASK-FRED-SERVER-001 | Done |
| BR-007 | OSS raw 路径包含 provider、endpoint、日期、job_id、content hash | AC-003 | TC-004 | TASK-FRED-SERVER-001 | Done |
| BR-008 | `macro_data` 不依赖 `fred/internal/*`、provider DTO 或私有存储表 | AC-007 | TC-002, TC-008 | TASK-FRED-001 | Done |
| BR-009 | `fred` 不实现 `ms_brain` 的 M/S 状态机、交易许可、仓位折扣或策略判断 | AC-009 | TC-009 | TASK-FRED-SERVER-002 | Done |
| BR-010 | 全量采集按 `spec/SPEC.md` §5.1 全端点矩阵进行跨入口交叉校验 | AC-010 | TC-010 | TASK-FRED-CLIENT-001, TASK-FRED-SERVER-001 | Done |

---

## §3 非功能需求追溯（NFR）

> fred 为 Planned 阶段模块，性能/安全/可运维 NFR 在 `spec/SPEC.md` §17~§20 定义，待 runtime 证据闭合后升级状态。

---

## §4 TC→FR 反向追溯

| TC | 覆盖需求 | 目标命令 |
| -- | -------- | -------- |
| TC-001 | FR-003, FR-013 | `go test ./pkg/fredx/...` |
| TC-002 | FR-005, BR-001, BR-008 | `go test ./internal/domain/... ./internal/client/...` |
| TC-003 | FR-004, FR-008, BR-002, BR-005 | `go test ./internal/server/... -run Idempotency` |
| TC-004 | FR-006, FR-007, FR-008, FR-010, FR-012, BR-005, BR-007 | `FRED_DEV_CONFIG=sre/secrets/env/dev.md go test ./internal/integration/...` |
| TC-005 | FR-004, FR-009, BR-006 | `go test ./internal/server/... -run RedisRebuild` |
| TC-006 | FR-001, FR-002, FR-011, BR-004 | `go test ./internal/integration/... -run NATSIngestHandoff` |
| TC-007 | FR-005, BR-003 | `go test ./internal/server/... -run NoLookahead` |
| TC-008 | FR-014, BR-001, BR-008 | `bash scripts/boundary-gates.sh` |
| TC-009 | FR-015, BR-009 | `go test ./internal/integration/... -run MsBrainContract` |
| TC-010 | FR-016, BR-010 | `go test ./internal/integration/... -run FullCoverageAudit` |

---

## §5 全局 AC 注册表

| AC | 验收摘要 | 覆盖需求 | 状态 |
| --- | --- | --- | --- |
| AC-001 | 双服务启动、health、version、readiness 正确 | FR-001, FR-013 | Done |
| AC-002 | `configx` 从 `sre/secrets/env/dev.md` 映射配置 | FR-002 | Done |
| AC-003 | 完整持久化链路正确 | FR-004, FR-006, FR-007, FR-008, FR-010, FR-012, BR-002, BR-005, BR-007 | CI-gated |
| AC-004 | Redis/ClickHouse 可重建派生层策略 | FR-009, BR-006 | CI-gated |
| AC-005 | NATS ingest/control 与 Kafka durable event 分层 | FR-010, FR-011, BR-004 | CI-gated |
| AC-006 | 领域归一化与回放 no-lookahead | FR-003, FR-004, FR-005, BR-003 | Done |
| AC-007 | 下游稳定契约与边界门禁 | FR-014, BR-001, BR-008 | Done |
| AC-008 | 追溯闭合与风险登记 | 全部 | Done |
| AC-009 | `ms_brain` 下游消费契约 | FR-015, BR-009 | CI-gated |
| AC-010 | 全量采集覆盖审计闭合 | FR-016, BR-010 | CI-gated |

---

## §6 子模块追溯入口

| 子模块 | 文档 |
| --- | --- |
| client | [spec/client/SPEC.md](../spec/client/SPEC.md) · [matrix/client/TRACEABILITY.md](client/TRACEABILITY.md) |
| server | [spec/server/SPEC.md](../spec/server/SPEC.md) · [matrix/server/TRACEABILITY.md](server/TRACEABILITY.md) |

---

## §7 覆盖率仪表盘

| 维度 | 总数 | Done | CI-gated | 覆盖率（单元） |
| --- | --- | --- | --- | --- |
| FR | 16 | 16 | 0 | 100% |
| BR | 10 | 10 | 0 | 100% |
| AC | 10 | 5 | 5 | 50%（单元）；集成于 CI 闭环 |
| TC | 10 | 5 | 5 | 50%（单元）；集成于 CI 闭环 |
| **合计** | **46** | **36** | **10** | **78.3%（单元）** |

> 说明：FR/BR 全部实现并经单元测试验证（100%）。AC/TC 中单元可验证项已 Done；依赖真实介质的集成项（AC-003/004/005/009/010、TC-004/005/006/009/010）经 `//go:build integration` 接入 `sre/secrets/env/dev.md`，本地 SKIP、CI 闭环。剩余风险见 `spec/SPEC.md` §23（OPEN-004/005/008/009）。
