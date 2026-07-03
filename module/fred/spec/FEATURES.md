# fred 完整实现清单

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Generated from current module SSOT |
| Last-Updated | 2026-07-03 |
| Module-Version | v1.0.0 |
| Module-State | 目标规格已定义；runtime 仍需从旧 `Stores=None` 口径迁移 |
| Layer | 数据域 · 宏观 |
| Module-Type | 独立 C/S Module（client/server 双服务） |
| Runtime-Repo | `/home/workspace/fred` |
| Config-Source | `sre/secrets/env/dev.md` |
| Sources | `goal/goal.md`、`spec/SPEC.md`、`matrix/TRACEABILITY.md`、`plan/PLAN.md` |

本文档是 `module/fred/` 当前规格库的功能投影，用于说明 `fred`
最终必须具备的模块能力和剩余闭合面。它不是 runtime 通过证明；通过证明以
`spec/ACCEPTANCE.md` 的命令、验收项和证据为准。

## 模块边界

| 维度 | 定义 |
| --- | --- |
| 业务责任 | 从 FRED 拉取宏观序列、观测、发布日历和 vintage/revision 数据，并形成可追溯、可重放、无前视的数据产品。 |
| 服务形态 | 独立 C/S 服务：`cmd/fred-client` 负责采集与发布，`cmd/fred-server` 负责消费、持久化与查询。 |
| 领域共享层 | 所有出域数据必须归一化为 `domain_macro` 领域模型；下游不得依赖 provider DTO 或内部存储表。 |
| 共享基座 | 配置、日志、指标、追踪、健康检查、存储适配器、消息适配器和边界 gate 必须通过共享基座组件接入。 |
| 持久化/消息 | `taos`、`kafka`、`postgres`、`Redis`、`oss`、`nats`、`clickhouse` 均在目标边界内，各自职责不可互相替代。 |
| 配置来源 | 开发环境配置只允许引用 `sre/secrets/env/dev.md` 的键名和装载约定，不得复制 secret 值。 |
| 禁止所有权 | `fred` 不拥有宏观领域模型、不拥有跨 provider 聚合策略、不拥有交易、风控或分析引擎决策逻辑。 |
| 边界证明 | `scripts/boundary-gates.sh` 必须禁止绕过共享基座直接连接基础设施。 |

## 功能投影

| ID | 功能 | 当前状态 | 已有证据 | 剩余实现面 |
| --- | --- | --- | --- | --- |
| FR-001 | `fred-client`/`fred-server` 双进程启动、生命周期、health、ready/live、优雅关闭、版本输出 | Planned | `spec/SPEC.md` 已定义 | runtime 需提供双服务启动与健康证据 |
| FR-002 | 从 `sre/secrets/env/dev.md` 装载配置，禁止复制 secret 值 | Planned | `spec/SPEC.md` 配置源已定义 | runtime 需接入共享 `configx`，并完成 secret scan |
| FR-003 | FRED client 覆盖 `spec/SPEC.md` §5.1 全端点矩阵与核心指标包，并支持分页、限流、退避重试、错误分类、请求审计字段 | Planned | `spec/SPEC.md` FR 与 TC 已定义 | `/home/workspace/fred/pkg/fredx` 需完成 SDK 行为测试 |
| FR-004 | 支持 backfill、incremental、series sync、revision scan，并生成 job、checkpoint、idempotency key | Planned | `spec/SPEC.md` 写明作业模型 | runtime 需落地 job 状态机和幂等账本 |
| FR-005 | provider 响应归一化到 `domain_macro`，保留 `released_at`、`available_at`、`vintage_at` | Planned | `spec/SPEC.md` 领域模型已定义 | 需确认 `domain_macro` 实际包路径和字段映射 |
| FR-006 | 原始 provider 响应先写入 `oss`，再归一化、写多存储、发事件 | Planned | `spec/SPEC.md` 写明 raw-first 顺序 | runtime 需实现内容 hash、路径规则和失败回滚策略 |
| FR-007 | 有效观测写入 `taos`，支持按 series/time/vintage selector 查询 | Planned | `spec/SPEC.md` 存储职责已定义 | runtime 需实现 TDengine schema、写入和查询测试 |
| FR-008 | series metadata、release calendar、idempotency ledger、checkpoint 写入 `postgres` 事务边界 | Planned | `spec/SPEC.md` 存储职责已定义 | runtime 需实现事务写入和 checkpoint 完成顺序 |
| FR-009 | Redis 承载热序列缓存、锁、rate bucket、短游标，且可重建 | Planned | `spec/SPEC.md` BR 已定义 | runtime 需证明 cache clear 后可从权威存储重建 |
| FR-010 | Kafka 发布版本化事件，携带幂等键和无前视字段 | Planned | `spec/SPEC.md` 消息边界已定义 | runtime 需实现 topic、schema、producer 幂等与消费验证 |
| FR-011 | NATS 承载 client→server ingest handoff 与 reload/backfill/pause/resume/heartbeat 控制面，不替代 Kafka durable event | Planned | `spec/SPEC.md` 控制面边界已定义 | runtime 需证明 handoff 与 durable event 分离 |
| FR-012 | ClickHouse 保存分析读模型和校验输出，且可重建 | Planned | `spec/SPEC.md` read model 职责已定义 | runtime 需实现重建路径和分析查询证据 |
| FR-013 | API 提供 series metadata、observation query、job status、admin trigger | Planned | `spec/SPEC.md` API 表已定义 | runtime 需实现 C/S API、错误码和鉴权/管理边界 |
| FR-014 | 边界 gate 只允许通过共享基座接入目标存储适配器，禁止直接 infra connection | Planned | `spec/SPEC.md` AC/TC 已定义 | 需迁移旧 `Stores=None` boundary script 到完整存储边界 |
| FR-015 | 提供 `ms_brain` 下游消费画像，覆盖 PIT 宏观观测、修订、发布日历、freshness/degrade 和初始序列锚点 | Planned | `spec/SPEC.md` 已补充 `ms_brain` 初始数据契约 | runtime 需提供 integration profile、contract fixture 和无前视查询证据 |
| FR-016 | 全量采集覆盖审计：series/release/category/tag/source/updates 六域覆盖率、默认 `1990-01-01` 全量起点、最近 3 个月修订回拉、`realtime_start/realtime_end` 版本闭合与缺口重采可追踪 | Planned | `spec/SPEC.md` 已定义覆盖审计要求 | runtime 需实现 coverage report、缺口回补与验收阈值 |

## 业务规则

| ID | 规则 | 验收含义 |
| --- | --- | --- |
| BR-001 | 下游只能依赖公开 API、Kafka 事件、`pkg/fredx` 和 `domain_macro` 模型。 | 内部 provider DTO 和私有存储表不得成为跨模块契约。 |
| BR-002 | 相同 provider/series/period/vintage 重复写入必须幂等。 | 重放、重试、重复 backfill 不得产生重复事实或重复 durable event。 |
| BR-003 | `available_at` 是无前视判定依据。 | as-of 查询不得暴露查询时点之后才可获得的 vintage。 |
| BR-004 | Kafka 是 durable event，NATS 只做 ingest/control plane。 | NATS 消息丢失不得等同于业务事件丢失；Kafka 不得被 NATS 替代。 |
| BR-005 | Postgres checkpoint 必须先于 backfill completed 状态落地。 | 作业完成态必须可追溯、可恢复。 |
| BR-006 | Redis 和 ClickHouse 只允许作为可重建派生层。 | 清空缓存或读模型后，系统可从权威存储恢复。 |
| BR-007 | OSS raw path 必须包含 provider、endpoint、date、job_id、content hash。 | 原始响应可审计、可去重、可重放。 |
| BR-008 | `domain_macro` 不得依赖 `fred/internal`、provider DTO 或私有存储表。 | 领域共享层保持独立，防止数据域反向污染。 |
| BR-009 | `fred` 只向 `ms_brain` 提供宏观数据、事件、质量和版本契约，不实现 M/S 状态机、交易许可、仓位折扣或策略判断。 | 下游策略逻辑留在 `ms_brain`，`fred` 保持数据域 provider 服务边界。 |
| BR-010 | 全量采集必须按 `spec/SPEC.md` §5.1 全端点矩阵进行跨入口交叉校验。 | 禁止单入口口径宣称“完整”，必须产出 coverage 审计证据。 |

## 文档资产

| 文件 | 用途 | 当前状态 |
| --- | --- | --- |
| `goal/goal.md` | 模块目标与业务价值 | Present |
| `spec/SPEC.md` | 23 节规格、FR/BR/AC/TC 源头 | Present |
| `spec/client/SPEC.md` | client 子模块规格 | Present |
| `spec/server/SPEC.md` | server 子模块规格 | Present |
| `matrix/TRACEABILITY.md` | Goal、FR、BR、AC、TC 追溯矩阵 | Present |
| `plan/PLAN.md` | 实施顺序、依赖、风险和验证命令 | Present |
| `spec/FEATURES.md` | 功能投影和剩余实现面 | Present |
| `spec/ACCEPTANCE.md` | 验收标准、命令和证据闭合 | Present |

## 当前缺口

1. `/home/workspace/fred` 旧边界脚本仍需从 `Stores=None` 迁移到 `taos`、`kafka`、`postgres`、`Redis`、`oss`、`nats`、`clickhouse` 完整目标。
2. `domain_macro` 的实际 Go 包路径、字段名和版本契约仍需在 runtime 实现前确认。
3. `sre/secrets/env/dev.md` 只能作为配置键名和装载约定来源，不能把 secret 值复制到 `module/fred/` 或 `/home/workspace/fred`。
4. 集成验收依赖 dev 环境中的 FRED 凭证和七类基础设施可用性；未满足前只能完成文档与单元级验证。
5. `ms_brain` 当前证据主要来自文档、spec 和 YAML 配置；在其 runtime 落地前，`fred` 先用 contract fixture 和回放样例闭合消费契约。
6. 全量采集覆盖审计（FR-016/BR-010）需补齐跨入口计数对账和缺口重采机制。
