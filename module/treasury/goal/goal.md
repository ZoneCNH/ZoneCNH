# treasury Goal

## 元数据

| 字段 | 值 |
| ---- | -- |
| Module | `treasury` |
| Domain | 数据域 · 宏观 |
| Goal-ID | `GOAL-TREASURY-001` |
| Status | Planned（Production Target） |
| Owner | 数据域 |
| Last-Updated | 2026-07-03 |
| Source-Code | `/home/workspace/treasury/` |
| Template-Reference | `module/binance`（C/S 模块样板） |

## 目标陈述

把 `treasury` 建设为美国国债/财政数据的生产级独立 C/S 服务集群：数据域各子模块（`yield`、`auction`、`fiscal`、`tic`）均可独立部署，统一复用共享基座组件，统一使用 `domain_macro` 领域共享层，统一落地 `taos + kafka + postgres + Redis + oss + nats + clickhouse` 全链路持久化与消息分发。

## 采集子模块（独立 C/S 服务）

| 子模块 | 服务单元 | 数据范围 | 默认更新频率 | 默认历史起点 |
| ------ | -------- | -------- | ------------ | ------------ |
| `yield` | `treasury-yield-client/server` | Daily Treasury Par/Real/Bill/Long-Term Yield Curve | 每交易日 + 发布窗口轮询 | `1990-01-01` |
| `auction` | `treasury-auction-client/server` | TreasuryDirect 拍卖日历、公告、结果、发行结构 | 拍卖日高频，非拍卖日日频 | `2003-01-01` |
| `fiscal` | `treasury-fiscal-client/server` | DTS、MTS、Debt to the Penny、Revenue、Exchange Rates | DTS 小时级；MTS 月度发布后同步 | DTS:`2005-01-01` / MTS:`2000-01-01` / Debt:`1993-01-01` |
| `tic` | `treasury-tic-client/server` | TIC 月度国际资本流动与持仓结构 | 月度发布周增强同步 | `2000-01-01` |

## 成功标准

| ID | 成功标准 |
| -- | -------- |
| G-SC-001 | 四个子模块均可独立以 C/S 形态启动、升级、回放，不依赖单体进程。 |
| G-SC-002 | 所有运行配置通过共享配置组件映射，模块文档与源码不复制密钥值。 |
| G-SC-003 | 采集结果全部归一化为 `domain_macro` 语义，并携带 no-lookahead 所需时间字段。 |
| G-SC-004 | 完成 `taos`、`kafka`、`postgres`、`Redis`、`oss`、`nats`、`clickhouse` 职责分配且可验证。 |
| G-SC-005 | 每个子模块具备“历史起点 + 增量 + 修订回拉 + 对账”的同步闭环。 |
| G-SC-006 | 对外只暴露 API、Kafka 事件和领域共享模型，下游不依赖 provider DTO。 |
| G-SC-007 | 为宏观分析输出期限结构、供需、财政脉冲、海外需求等可追溯特征基础。 |

## 非目标

| ID | 非目标 |
| -- | ------ |
| G-NG-001 | 不在 `treasury` 内实现宏观多 provider 聚合或跨源冲突仲裁（属于 `macro_data`）。 |
| G-NG-002 | 不在 `treasury` 内实现因子建模、策略决策或交易执行。 |
| G-NG-003 | 不把 provider 原始字段直接作为跨模块长期契约。 |
| G-NG-004 | 不绕过共享基座组件直接手写基础设施客户端。 |

## 边界原则

| ID | 原则 |
| -- | ---- |
| G-BD-001 | `treasury` 是 provider 专属数据服务，负责采集、归一化、持久化、查询与事件分发。 |
| G-BD-002 | `domain_macro` 是跨模块领域语义唯一出口。 |
| G-BD-003 | `macro_data` 只能通过契约消费 `treasury`，不得反向拥有 provider 逻辑。 |
| G-BD-004 | NATS 仅承载 ingest/control；Kafka 仅承载 durable downstream event。 |

## 风险

| ID | 风险 | 控制 |
| -- | ---- | ---- |
| G-R-001 | Treasury 源站发布时点波动导致滞后 | 采用“发布驱动优先 + 定时轮询兜底 + freshness SLA” |
| G-R-002 | 月频数据修订导致回测穿越 | 强制记录 `released_at/available_at/vintage_at`，执行回拉窗口 |
| G-R-003 | 多存储双写不一致 | 用 idempotency key、checkpoint、outbox、重放校验闭环 |
| G-R-004 | 子模块并行演进导致契约漂移 | 以 `matrix/TRACEABILITY.md` 与 API schema 做统一门禁 |
