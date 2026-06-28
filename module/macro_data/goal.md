# macro_data Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `macro_data` |
| 层级 | 数据域 · 宏观摄取与分发（L3 接收侧） |
| 仓库 | <https://github.com/ZoneCNH/macro_data> |
| 当前版本 | v0.1.0-spec |
| 目标版本 | v0.1.0 |
| 状态 | Docs Baseline — SPEC 已定义 FR/BR/NFR/AC，Runtime Pending |
| 最后更新 | 2026-06-29 |

## 目标

`macro_data` 是宏观 provider adapter 与内部宏观消费链路之间的接收侧模块。镜像 `market_data` 的接收侧设计，适配宏观领域语义（MacroPoint 三时间 + revision + no-lookahead gate）。接收 adapter 已归一化的宏观事件，执行接收侧校验、幂等判定、revision 排序约束、no-lookahead 可见性门禁和分发结果表达。

## 非目标

- 不实现 provider HTTP API client
- 不实现 provider DTO（FRED/ECB JSON 等）
- 不定义 proto/gRPC/REST schema（由 contracts 拥有）
- 不实现因子/预测/策略/回测逻辑
- 文档批准前不新增运行时代码

## 与 market_data 的镜像关系

本模块严格镜像 `module/market_data` 的接收侧设计，仅替换领域语义：

| market_data | macro_data | 差异 |
| --- | --- | --- |
| DownstreamDispatchPort | MacroDispatchPort | 端口镜像 |
| 12 字段（行情侧） | 12 字段（宏观侧） | provider/series_code/三时间/revision |
| 8 reject reason | 9 reject reason | 多 lookahead_violation |
| MarketFactEnvelope | MacroPoint | 领域载荷 |
| stale/future gate | no-lookahead gate | **核心差异** |

## 当前阻塞

| 优先级 | 阻塞项 | 处理方向 |
| --- | --- | --- |
| P0 | Runtime Pending — 无运行时代码 | Contract/Domain/Adapter Gate 通过后启动 |
| P1 | Domain Gate: domain_macro 运行时发布 MacroPoint | 当前 docs baseline，运行时待冻结 |
| P2 | Adapter Gate: 各宏观 adapter 引用 dispatch port | 待 fred/bea/ecb 等 SPEC 补充引用 |
