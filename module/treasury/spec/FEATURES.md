# treasury 完整实现清单

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Generated from current module SSOT |
| Last-Updated | 2026-07-03 |
| Module-Version | v0.2.0 |
| Module-State | Production Target（Planned） |
| Layer | 数据域 · 宏观 |
| Module-Type | 独立 C/S Module（`yield`/`auction`/`fiscal`/`tic`） |
| Runtime-Repo | `/home/workspace/treasury` |
| Sources | `goal/goal.md`、`spec/SPEC.md`、`matrix/TRACEABILITY.md`、`plan/PLAN.md` |

本文档是 `module/treasury/` 当前规格资产的功能投影，说明目标能力与剩余闭合面。运行时通过证明以 `spec/ACCEPTANCE.md` 为准。

## 模块边界

| 维度 | 定义 |
| --- | --- |
| 服务形态 | 四个子模块均为独立 C/S 服务单元，可独立部署与扩容。 |
| 领域共享层 | 对外语义统一为 `domain_macro`，下游不依赖 provider DTO。 |
| 共享基座 | 配置、日志、指标、追踪、弹性与基础设施适配器全部复用共享基座组件。 |
| 持久化/消息 | `taos`、`kafka`、`postgres`、`Redis`、`oss`、`nats`、`clickhouse` 均在目标边界内。 |
| 禁止所有权 | 不承载聚合仲裁、因子计算、策略/交易/风控决策。 |

## 功能投影

| ID | 功能 | 当前状态 | 剩余实现面 |
| --- | --- | --- | --- |
| FR-TRY-001 | 四子模块 client/server 独立启动与健康检查 | Planned | runtime 双服务入口与生命周期证据 |
| FR-TRY-002 | 配置从共享组件加载，secret 仅引用不落盘 | Planned | config schema + redaction 测试 |
| FR-TRY-003 | 收益率曲线采集（Par/Real/Bill/Long-Term） | Planned | 端点覆盖、期限结构标准化 |
| FR-TRY-004 | 拍卖日历/公告/结果采集 | Planned | 拍卖状态机与幂等更新 |
| FR-TRY-005 | 财政/债务数据采集（DTS/MTS/Debt/Revenue/FX） | Planned | 日频/月频调度与发布触发 |
| FR-TRY-006 | TIC 月度数据采集与修订管理 | Planned | 版本链与月度回拉 |
| FR-TRY-007 | `domain_macro` 归一化与 no-lookahead 字段闭合 | Planned | `available_at/vintage_at` 全链验证 |
| FR-TRY-008 | raw-first OSS 归档 | Planned | hash 路径规则与回放入口 |
| FR-TRY-009 | NATS ingest/control plane | Planned | handoff 与控制命令契约 |
| FR-TRY-010 | Postgres metadata/checkpoint/ledger | Planned | 事务边界与恢复路径 |
| FR-TRY-011 | taos 时序写入与查询 | Planned | 按期限/时间/vintage 查询 |
| FR-TRY-012 | Kafka durable event | Planned | schema version + idempotency key |
| FR-TRY-013 | ClickHouse 分析读模型 | Planned | 可重建宽表与物化视图 |
| FR-TRY-014 | Redis 缓存/锁/限流 | Planned | 可重建性与高并发测试 |
| FR-TRY-015 | 查询/API/作业控制能力 | Planned | API 契约与 admin 边界 |
| FR-TRY-016 | 覆盖率审计 + 增量/全量重同步 + 缺口重采闭环 | Planned | 审计报表、重采任务、证据闭合 |

## 业务规则

| ID | 规则 | 状态 |
| --- | --- | --- |
| BR-TRY-001 | 子模块保持独立 C/S 边界 | Planned |
| BR-TRY-002 | `available_at` 是 no-lookahead 判定依据 | Planned |
| BR-TRY-003 | 同键写入必须幂等 | Planned |
| BR-TRY-004 | NATS 与 Kafka 分层不可混用 | Planned |
| BR-TRY-005 | checkpoint 先于 completed | Planned |
| BR-TRY-006 | Redis/ClickHouse 仅可重建层 | Planned |
| BR-TRY-007 | OSS raw 路径含 hash 与作业元数据 | Planned |
| BR-TRY-008 | 下游只依赖 API/Kafka/domain_macro | Planned |
| BR-TRY-009 | 发布触发优先（ET 16:00 窗口），轮询兜底 | Planned |
| BR-TRY-010 | 历史起点与回拉窗口可审计 | Planned |

## 当前缺口

1. `/home/workspace/treasury` 运行时服务骨架与边界脚本尚待落地。
2. 四子模块端点覆盖、频率调度、历史起点回补仍处于规格态。
3. 七类介质链路缺少 runtime 集成证据与回放验证。
4. 宏观分析补充项（surprise、跨源对账、质量分级）需在 API/事件层补齐。
