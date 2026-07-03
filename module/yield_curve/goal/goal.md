# yield_curve Goal

## 元数据

| 字段 | 值 |
| ---- | -- |
| Module | `yield_curve` |
| Domain | 数据域 · 宏观 |
| Goal-ID | `GOAL-YC-001` |
| Status | Planned（Production Target） |
| Owner | 数据域 |
| Last-Updated | 2026-07-03 |
| Source-Code | `/home/workspace/yield_curve/` |
| Template-Reference | `module/binance`（C/S 模块样板） |

## 目标陈述

把 `yield_curve` 建设为 BoE（Bank of England）Anderson-Sleath 收益率曲线的生产级独立 C/S 服务集群：各曲线子模块独立部署，统一复用共享基座组件，统一使用 `domain_macro` 领域共享层，统一落地 `taos + kafka + postgres + Redis + oss + nats + clickhouse` 全链路持久化与消息分发。

## 采集子模块（独立 C/S 服务）

| 子模块 | 服务单元 | 数据范围 | 默认更新频率 | 默认历史起点 |
| ------ | -------- | -------- | ------------ | ------------ |
| `nominal_gilt` | `yc-nominal-client/server` | 名义金边债收益率曲线（spot/forward） | 日频 + 月末归档 | `1979-01-01` |
| `real_gilt` | `yc-real-client/server` | 实际（通胀挂钩）金边债曲线 | 日频 + 月末归档 | `1985-01-01` |
| `implied_inflation` | `yc-inflation-client/server` | 隐含通胀曲线 | 日频 + 月末归档 | `1985-01-01` |
| `ois` | `yc-ois-client/server` | 隔夜指数掉期曲线 | 日频 + 月末归档 | `2009-01-01` |
| `blc` | `yc-blc-client/server` | 商业银行负债曲线（归档专用） | 月频归档为主 | `2000-01-01` |

## 成功标准

| ID | 成功标准 |
| -- | -------- |
| G-SC-001 | 五个曲线子模块均可独立以 C/S 形态启动、升级、回放。 |
| G-SC-002 | 配置、日志、追踪、弹性、存储访问全部通过共享基座组件。 |
| G-SC-003 | 采集结果统一映射到 `domain_macro` 并携带 no-lookahead 时间语义。 |
| G-SC-004 | 完成七类介质（`taos/kafka/postgres/Redis/oss/nats/clickhouse`）职责分配且可验证。 |
| G-SC-005 | 双路径采集（latest/archive）与 BLC 归档强制路由闭合。 |
| G-SC-006 | 支持增量、全量、手动重同步与可审计数据来源标记。 |
| G-SC-007 | 为宏观分析提供期限利差、通胀预期、政策传导与跨市场对比基础。 |

## 非目标

| ID | 非目标 |
| -- | ------ |
| G-NG-001 | 不在 `yield_curve` 内实现跨 provider 聚合仲裁。 |
| G-NG-002 | 不在 `yield_curve` 内实现策略决策、交易执行或风险控制。 |
| G-NG-003 | 不将 provider 原始 Excel 布局暴露为外部长期契约。 |
| G-NG-004 | 不绕过共享基座组件直接手写基础设施客户端。 |

## 边界原则

| ID | 原则 |
| -- | ---- |
| G-BD-001 | `yield_curve` 是收益率曲线 provider 专属数据服务，负责采集、归一化、持久化与分发。 |
| G-BD-002 | `domain_macro` 是跨模块语义唯一出口。 |
| G-BD-003 | 下游通过 API/Kafka/领域模型消费，不依赖内部 DTO 或存储表。 |
| G-BD-004 | NATS 仅承载 ingest/control，Kafka 仅承载 durable downstream event。 |

## 风险

| ID | 风险 | 控制 |
| -- | ---- | ---- |
| G-R-001 | BoE Excel 布局变更导致解析失败 | 引入期限行内容检测与 schema drift 隔离 |
| G-R-002 | latest 与 archive 口径差异导致覆盖缺口 | 记录 `source/source_url` 并做交叉对账 |
| G-R-003 | 历史归档多工作簿拼接错误 | 建立分段校验与连续性检查 |
| G-R-004 | 缓存策略不当导致滞后或成本上升 | latest 24h / archive 30d 分层缓存与命中监控 |

