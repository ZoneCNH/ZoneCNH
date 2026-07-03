# module/bea GOAL

## 元数据

| 字段 | 值 |
| --- | --- |
| 模块 | `bea` |
| 层级 | 数据域 · 宏观（独立 C/S Module） |
| 仓库 | <https://github.com/ZoneCNH/bea> |
| Runtime-Repo | `/home/workspace/bea` |
| 状态 | Planned（Production Target） |
| Spec-Version | v0.2.0 |

## Purpose

`module/bea` 定义 BEA 数据源的生产级宏观采集模块：client 负责采集与归一化，server 负责消费、持久化、查询与事件分发。

## Primary Goal

1. 建立 BEA 各数据集独立可追溯采集链路（全量 + 增量 + 重同步）。
2. 强制 C/S 独立服务边界与共享基座复用。
3. 统一 `domain_macro` 语义输出并实现 no-lookahead 约束。
4. 形成可审计多介质链路：`taos + kafka + postgres + Redis + oss + nats + clickhouse`。

## Non-Goals

- 不在 `bea` 内实现跨 provider 聚合仲裁（由更上层模块负责）。
- 不在 `bea` 内实现因子、策略、回测或交易逻辑。
- 不向下游暴露 BEA 原始字段命名作为长期契约。

## Success Criteria

1. `bea-client` 与 `bea-server` 独立启动并通过 health/readiness。
2. 采集清单覆盖 NIPA/NIUnderlyingDetail/FixedAssets/ITA/Regional 等核心数据集。
3. 增量、全量、手动重同步可执行，且 checkpoint/幂等账本可审计。
4. `macro_data` 与分析域仅依赖 API/Kafka/`domain_macro` 语义，不依赖 `internal/*`。
