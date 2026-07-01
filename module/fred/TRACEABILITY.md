# fred 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-30
Source: [SPEC.md](SPEC.md) | Goal: GOAL-FRED-001 | Status: Draft

---

## Goal 到需求

| Goal / SC | FR | BR | AC | TC |
| --------- | -- | -- | -- | -- |
| G-SC-001 独立进程 | FR-001, FR-013 | BR-008 | AC-001 | TC-006 |
| G-SC-002 配置不泄密 | FR-002 | BR-006 | AC-002 | TC-006 |
| G-SC-003 领域归一化 | FR-003, FR-005 | BR-001, BR-002 | AC-006 | TC-001, TC-002, TC-005 |
| G-SC-004 完整持久化 | FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012 | BR-004, BR-005, BR-006, BR-007 | AC-003, AC-004, AC-005 | TC-003, TC-004 |
| G-SC-005 下游稳定契约 | FR-010, FR-013, FR-014, FR-015 | BR-001, BR-004, BR-008, BR-009 | AC-005, AC-007, AC-009 | TC-006, TC-009 |
| G-SC-006 回放与 no-lookahead | FR-004, FR-005, FR-006, FR-008 | BR-002, BR-003, BR-007 | AC-003, AC-006 | TC-003, TC-005 |

---

## §1 功能需求追溯（FR）

| FR | 需求摘要 | AC | TC ID(s) | Task | 状态 |
| -- | -------- | -- | -------- | ---- | ---- |
| FR-001 | `bootstrap` 启动、health、version | AC-001 | TC-006 | - | Planned |
| FR-002 | `configx` 从 `sre/secrets/env/dev.md` 映射配置 | AC-002 | TC-006 | - | Planned |
| FR-003 | FRED client 分页、限流、重试、错误分类 | AC-006 | TC-001 | - | Planned |
| FR-004 | backfill / incremental / series sync / revision scan | AC-003, AC-006 | TC-003, TC-005 | - | Planned |
| FR-005 | 转换为 `domain_macro` 并记录信息集时间 | AC-006 | TC-002, TC-005 | - | Planned |
| FR-006 | OSS raw 先归档再规范化写入 | AC-003 | TC-004 | - | Planned |
| FR-007 | TDengine observation 写入和查询 | AC-003 | TC-004 | - | Planned |
| FR-008 | Postgres metadata / idempotency / checkpoint | AC-003 | TC-003, TC-004 | - | Planned |
| FR-009 | Redis cache / lock / rate bucket / cursor | AC-004 | TC-004 | - | Planned |
| FR-010 | Kafka durable event stream | AC-003, AC-005 | TC-003, TC-004 | - | Planned |
| FR-011 | NATS control plane | AC-005 | TC-004 | - | Planned |
| FR-012 | ClickHouse analysis read model | AC-003 | TC-004 | - | Planned |
| FR-013 | 服务 API | AC-001, AC-003 | TC-006 | - | Planned |
| FR-014 | 边界门禁允许目标存储、禁止绕过基座 | AC-007 | TC-006 | - | Planned |
| FR-015 | `ms_brain` 下游消费画像、初始序列锚点、PIT/as-of、发布/修订事件和 freshness/degrade 契约 | AC-009 | TC-009 | - | Planned |

---

## §2 业务规则追溯（BR）

| BR | 规则摘要 | AC | TC ID(s) | Task | 状态 |
| -- | -------- | -- | -------- | ---- | ---- |
| BR-001 | 不暴露 provider DTO，对外只出服务 API / Kafka 事件 / `pkg/fredx` / `domain_macro` | AC-007 | TC-002, TC-008 | - | Planned |
| BR-002 | 相同 provider / series / period / vintage 写入幂等 | AC-003 | TC-003 | - | Planned |
| BR-003 | `available_at` 是 no-lookahead 判定依据，晚于 `released_at` 时下游只能在 `available_at` 后使用 | AC-006 | TC-007 | - | Planned |
| BR-004 | Kafka 是 durable business event，NATS 只承载 control plane | AC-005 | TC-006 | - | Planned |
| BR-005 | Postgres checkpoint 成功推进前，backfill job 不得进入 completed | AC-003 | TC-003, TC-004 | - | Planned |
| BR-006 | Redis 与 ClickHouse 均为可重建派生层，不作为唯一权威源 | AC-004 | TC-005 | - | Planned |
| BR-007 | OSS raw 路径包含 provider、endpoint、日期、job_id、content hash | AC-003 | TC-004 | - | Planned |
| BR-008 | `macro_data` 不依赖 `fred/internal/*`、provider DTO 或私有存储表 | AC-007 | TC-002, TC-008 | - | Planned |
| BR-009 | `fred` 不实现 `ms_brain` 的 M/S 状态机、交易许可、仓位折扣或策略判断 | AC-009 | TC-009 | - | Planned |

---

## §3 非功能需求追溯（NFR）

> fred 为 Draft 阶段模块，暂无独立 NFR 定义。性能/安全/质量需求将在 v0.2.0 准入阶段补充。

---

## §4 TC→FR 反向追溯

| TC | 覆盖需求 | 目标命令 |
| -- | -------- | -------- |
| TC-001 | FR-003 | `go test ./pkg/fredx/...` |
| TC-002 | FR-005, BR-001, BR-008 | `go test ./internal/domain/... ./internal/client/...` |
| TC-003 | FR-004, FR-008, FR-010, BR-002, BR-005 | `go test ./internal/server/... -run Idempotency` |
| TC-004 | FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, BR-005, BR-007 | `FRED_DEV_CONFIG=sre/secrets/env/dev.md go test ./internal/integration/...` |
| TC-005 | FR-004, FR-005, BR-006 | `go test ./internal/server/... -run RedisRebuild` |
| TC-006 | FR-001, FR-002, FR-013, FR-014, BR-004 | `go test ./internal/integration/... -run NATSControl` |
| TC-007 | BR-003 | `go test ./internal/server/... -run NoLookahead` |
| TC-008 | BR-001, BR-008 | `bash scripts/boundary-gates.sh` |
| TC-009 | FR-015, BR-009 | `go test ./internal/integration/... -run MsBrainContract` |

---

## §5 全局 AC 注册表

| AC | 验收摘要 | 覆盖需求 | 状态 |
| --- | --- | --- | --- |
| AC-001 | `bootstrap` 启动、health、version 正确 | FR-001, FR-013 | Planned |
| AC-002 | `configx` 从 `sre/secrets/env/dev.md` 映射配置 | FR-002 | Planned |
| AC-003 | 完整持久化链路正确 | FR-004, FR-006, FR-007, FR-008, FR-010, FR-012, BR-002, BR-005, BR-007 | Planned |
| AC-004 | Redis/ClickHouse 可重建派生层策略 | FR-009, BR-006 | Planned |
| AC-005 | Kafka durable event / NATS control plane | FR-010, FR-011, BR-004 | Planned |
| AC-006 | 领域归一化与回放 no-lookahead | FR-003, FR-004, FR-005, BR-003 | Planned |
| AC-007 | 下游稳定契约与边界门禁 | FR-014, BR-001, BR-008 | Planned |
| AC-008 | (预留) | — | Planned |
| AC-009 | `ms_brain` 下游消费契约 | FR-015, BR-009 | Planned |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 15 | 0 | 0% |
| BR | 9 | 0 | 0% |


| AC | 9 | 0 | 0% |
| TC | 9 | 0 | 0% |
| **合计** | **42** | **0** | **0%** |

> 说明：fred 为 Draft 状态，全部需求初始为 Planned。

---

## §7 变更历史

| 日期 | 变更内容 |
| --- | --- |
| 2026-06-29 | Goal 管线对齐：英文标题中文化为 §1-§6 标准结构；§1 FR/§2 BR 表新增 Task 列；Goal→需求表保留为附录 |
| 2026-06-22 | 初始版本：Goal→需求映射、FR/BR 覆盖、TC 命令占位、未闭合项追踪；BR 编号漂移修正 |

---

## 未闭合项

| ID | 缺口 | 处理 |
| -- | ---- | ---- |
| GAP-001 | 当前 `/home/workspace/fred` 边界脚本仍体现旧零存储 adapter 口径 | 实施阶段 1 更新为目标服务存储白名单与基座强制规则 |
| GAP-002 | `domain_macro` 具体类型名和包路径需在代码实施前确认 | 实施阶段 2 先读取领域共享层并锁定契约 |
| GAP-003 | dev 配置键名需从 `sre/secrets/env/dev.md` 映射，但不能复制值 | 实施阶段 1 只生成 key mapping 和 redaction 测试 |
| GAP-004 | `ms_brain` 当前证据以文档、spec、YAML 配置为主，尚不能提供真实下游 runtime 消费证明 | 实施阶段 5 先提供 contract fixture；`ms_brain` runtime 落地后补端到端证据 |
| GAP-005 | BR 编号漂移已修正 | 2026-06-22 已闭合，记录为追溯修正证据 |
