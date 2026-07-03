# uk_cb Goal

## 元数据

| 字段 | 值 |
| ---- | -- |
| Module | `uk_cb` |
| Domain | 数据域 · 宏观 |
| Goal-ID | `GOAL-UK-CB-001` |
| Status | Draft |
| Owner | 数据域 |
| Last-Updated | 2026-07-04 |
| Source-Code | `/home/workspace/uk_cb/` |

## 目标陈述

把 `uk_cb` 建设为数据域 · 宏观的独立 C/S 服务集群：通过共享基座组件和 `domain_macro` 领域共享层，以 CBI 商业调查 + Companies House 工商注册为双主源，并结合 BoE/ONS/DMP 补充源，形成可审计、可回放、可扩展的生产级宏观数据供应能力。

## 成功标准

| ID | 成功标准 |
| -- | -------- |
| G-SC-001 | `uk_cb-client` 与 `uk_cb-server` 可独立部署、独立扩缩容。 |
| G-SC-002 | 各采集子模块（policy/balance_sheet/prices/growth/labor/rates）可独立 C/S 运行。 |
| G-SC-003 | 所有配置由共享配置组件映射，文档/源码不复制 secret 值。 |
| G-SC-004 | 采集事件全部归一化到 `domain_macro` 语义，禁止 provider DTO 泄漏。 |
| G-SC-005 | 七类存储/消息介质职责清晰并可闭环审计。 |
| G-SC-006 | 支持增量、历史回补、修订追踪和 no-lookahead 可见性。 |
| G-SC-007 | 为 `macro_data` 与分析域提供稳定 API/Kafka 契约。 |

## 非目标

| ID | 非目标 |
| -- | ------ |
| G-NG-001 | 不在 `uk_cb` 内实现跨 provider 聚合决策。 |
| G-NG-002 | 不在 `uk_cb` 内实现策略、仓位、风险决策。 |
| G-NG-003 | 不把 Redis/ClickHouse 定义为唯一权威源。 |
| G-NG-004 | 不绕过共享基座直连基础设施。 |
