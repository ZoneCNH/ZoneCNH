# fred Traceability Matrix

## 元数据

| 字段 | 值 |
| ---- | -- |
| Module | `fred` |
| Goal | `GOAL-FRED-001` |
| Spec | [SPEC.md](SPEC.md) |
| Status | Draft |
| Last-Updated | 2026-06-22 |

## Goal 到需求

| Goal / SC | FR | BR | AC | TC |
| --------- | -- | -- | -- | -- |
| G-SC-001 独立进程 | FR-001, FR-013 | BR-008 | AC-001 | TC-006 |
| G-SC-002 配置不泄密 | FR-002 | BR-006 | AC-002 | TC-006 |
| G-SC-003 领域归一化 | FR-003, FR-005 | BR-001, BR-002 | AC-006 | TC-001, TC-002, TC-005 |
| G-SC-004 完整持久化 | FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012 | BR-004, BR-005, BR-006, BR-007 | AC-003, AC-004, AC-005 | TC-003, TC-004 |
| G-SC-005 下游稳定契约 | FR-010, FR-013, FR-014, FR-015 | BR-001, BR-004, BR-008, BR-009 | AC-005, AC-007, AC-009 | TC-006, TC-009 |
| G-SC-006 回放与 no-lookahead | FR-004, FR-005, FR-006, FR-008 | BR-002, BR-003, BR-007 | AC-003, AC-006 | TC-003, TC-005 |

## 功能需求覆盖

| FR | 需求摘要 | AC | TC | 状态 |
| -- | -------- | -- | -- | ---- |
| FR-001 | `bootstrap` 启动、health、version | AC-001 | TC-006 | Planned |
| FR-002 | `configx` 从 `sre/secrets/env/dev.md` 映射配置 | AC-002 | TC-006 | Planned |
| FR-003 | FRED client 分页、限流、重试、错误分类 | AC-006 | TC-001 | Planned |
| FR-004 | backfill / incremental / series sync / revision scan | AC-003, AC-006 | TC-003, TC-005 | Planned |
| FR-005 | 转换为 `domain_macro` 并记录信息集时间 | AC-006 | TC-002, TC-005 | Planned |
| FR-006 | OSS raw 先归档再规范化写入 | AC-003 | TC-004 | Planned |
| FR-007 | TDengine observation 写入和查询 | AC-003 | TC-004 | Planned |
| FR-008 | Postgres metadata / idempotency / checkpoint | AC-003 | TC-003, TC-004 | Planned |
| FR-009 | Redis cache / lock / rate bucket / cursor | AC-004 | TC-004 | Planned |
| FR-010 | Kafka durable event stream | AC-003, AC-005 | TC-003, TC-004 | Planned |
| FR-011 | NATS control plane | AC-005 | TC-004 | Planned |
| FR-012 | ClickHouse analysis read model | AC-003 | TC-004 | Planned |
| FR-013 | 服务 API | AC-001, AC-003 | TC-006 | Planned |
| FR-014 | 边界门禁允许目标存储、禁止绕过基座 | AC-007 | TC-006 | Planned |
| FR-015 | `ms_brain` 下游消费画像、初始序列锚点、PIT/as-of、发布/修订事件和 freshness/degrade 契约 | AC-009 | TC-009 | Planned |

## 业务规则覆盖

| BR | 规则摘要 | AC | TC | 状态 |
| -- | -------- | -- | -- | ---- |
| BR-001 | 不暴露 provider DTO，对外只出服务 API / Kafka 事件 / `pkg/fredx` / `domain_macro` | AC-007 | TC-002, TC-008 | Planned |
| BR-002 | 相同 provider / series / period / vintage 写入幂等 | AC-003 | TC-003 | Planned |
| BR-003 | `available_at` 是 no-lookahead 判定依据，晚于 `released_at` 时下游只能在 `available_at` 后使用 | AC-006 | TC-007 | Planned |
| BR-004 | Kafka 是 durable business event，NATS 只承载 control plane | AC-005 | TC-006 | Planned |
| BR-005 | Postgres checkpoint 成功推进前，backfill job 不得进入 completed | AC-003 | TC-003, TC-004 | Planned |
| BR-006 | Redis 与 ClickHouse 均为可重建派生层，不作为唯一权威源 | AC-004 | TC-005 | Planned |
| BR-007 | OSS raw 路径包含 provider、endpoint、日期、job_id、content hash | AC-003 | TC-004 | Planned |
| BR-008 | `macro_data` 不依赖 `fred/internal/*`、provider DTO 或私有存储表 | AC-007 | TC-002, TC-008 | Planned |
| BR-009 | `fred` 不实现 `ms_brain` 的 M/S 状态机、交易许可、仓位折扣或策略判断 | AC-009 | TC-009 | Planned |

## 验证命令占位

| TC | 目标命令 |
| -- | -------- |
| TC-001 | `go test ./pkg/fredx/...` |
| TC-002 | `go test ./internal/domain/... ./internal/client/...` |
| TC-003 | `go test ./internal/server/... -run Idempotency` |
| TC-004 | `FRED_DEV_CONFIG=sre/secrets/env/dev.md go test ./internal/integration/...` |
| TC-005 | `go test ./internal/server/... -run RedisRebuild` |
| TC-006 | `go test ./internal/integration/... -run NATSControl` |
| TC-007 | `go test ./internal/server/... -run NoLookahead` |
| TC-008 | `bash scripts/boundary-gates.sh` |
| TC-009 | `go test ./internal/integration/... -run MsBrainContract` |

## 未闭合项

| ID | 缺口 | 处理 |
| -- | ---- | ---- |
| GAP-001 | 当前 `/home/fred` 边界脚本仍体现旧零存储 adapter 口径 | 实施阶段 1 更新为目标服务存储白名单与基座强制规则 |
| GAP-002 | `domain_macro` 具体类型名和包路径需在代码实施前确认 | 实施阶段 2 先读取领域共享层并锁定契约 |
| GAP-003 | dev 配置键名需从 `sre/secrets/env/dev.md` 映射，但不能复制值 | 实施阶段 1 只生成 key mapping 和 redaction 测试 |
| GAP-004 | `ms_brain` 当前证据以文档、spec、YAML 配置为主，尚不能提供真实下游 runtime 消费证明 | 实施阶段 5 先提供 contract fixture；`ms_brain` runtime 落地后补端到端证据 |
| GAP-005 | BR 编号漂移已修正：`rg -n "BR-00[1-9]" module/fred/SPEC.md module/fred/TRACEABILITY.md` 人工核对 BR-001..009 摘要与 SPEC.md:69-79 一一对应；AC/TC 映射与 ACCEPTANCE.md AC→BR / TC→BR 一致；G-SC-004 补 BR-006、去 BR-003 | 2026-06-22 已闭合，记录为追溯修正证据 |
