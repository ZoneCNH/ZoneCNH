# eastmoney Goal

## 元数据

| 字段 | 值 |
| ---- | -- |
| Module | `eastmoney` |
| Domain | 数据域 · 宏观 |
| Goal-ID | `GOAL-EASTMONEY-001` |
| Status | Draft |
| Owner | 数据域 |
| Last-Updated | 2026-07-04 |
| Source-Code | `/home/workspace/eastmoney/` |

## 目标陈述

把 `eastmoney` 建设为数据域 · 宏观的独立 C/S 服务：通过共享基座组件和 `domain_macro` 领域共享层接入东方财富数据，具备完整持久化、事件发布、查询、回放和 no-lookahead 语义能力，供 `macro_data` 与分析域稳定消费。

## 成功标准

| ID | 成功标准 |
| -- | -------- |
| G-SC-001 | `eastmoney-client`/`eastmoney-server` 可独立部署与扩缩容。 |
| G-SC-002 | 配置统一由 `configx` 映射，文档与源码不保存密钥值。 |
| G-SC-003 | 采集输出统一归一化为 `domain_macro` 语义模型。 |
| G-SC-004 | `taos/kafka/postgres/Redis/oss/nats/clickhouse` 七类介质职责清晰并闭环。 |
| G-SC-005 | 支持历史回补、增量同步、修订回拉和 as-of 查询。 |
| G-SC-006 | 下游只依赖服务 API、事件契约或领域共享层，不依赖 provider DTO。 |

## 非目标

| ID | 非目标 |
| -- | ------ |
| G-NG-001 | 不在 `eastmoney` 内实现跨 provider 宏观聚合（归 `macro_data`）。 |
| G-NG-002 | 不实现因子计算、策略决策、交易执行。 |
| G-NG-003 | 不暴露 provider 私有 DTO 作为跨模块长期契约。 |
| G-NG-004 | 不绕过共享基座直连基础设施。 |

## 边界原则

| ID | 原则 |
| -- | ---- |
| G-BD-001 | `eastmoney` 是 provider 专属采集服务，负责 Eastmoney 接入和 provider 级治理。 |
| G-BD-002 | `domain_macro` 是跨模块语义权威层，`eastmoney` 只做转换与发布。 |
| G-BD-003 | `macro_data` 消费 `eastmoney` 输出，不反向承载 Eastmoney 采集逻辑。 |
| G-BD-004 | 存储、消息、观测、弹性能力必须经共享基座组件接入。 |
