# ADR-009: User Data Stream (Private Flow) Scope Exclusion

> 状态：Accepted
> 日期：2026-07-06
> 决策者：ZoneCNH architecture
> 来源：report/binance/20260704.md 用户数据流分析 + SPEC §3 scope
> 仓库归属：ZoneCNH 主仓 `module/binance/`

## 背景

SPEC §3 明确声明 binance 模块「不包含交易下单、账户管理、私有交易策略或生产凭证」。binance 的定位是公有市场数据 ingestion 模块，所有 WebSocket 流均为公有流（trade/depth/kline/tick/aggTrade/fundingRate/markPrice）。

报告 `report/binance/20260704.md` §二 对 Binance 用户数据流（User Data Stream，私有流）做了完整分析，覆盖 19 种事件类型 × 4 产品线，包括：

- **账户更新类**：`outboundAccountPosition`（spot）、`ACCOUNT_UPDATE`（um_perp/cm_perp）、`BALANCE_POSITION_UPDATE`（options）、`balanceUpdate`（spot）、`externalLockUpdate`（spot）
- **订单更新类**：`executionReport`（spot）、`ORDER_TRADE_UPDATE`（um_perp/cm_perp/options）、`TRADE_LITE`（um_perp）、`listStatus`（spot OCO）
- **策略/算法类**：`STRATEGY_UPDATE`、`GRID_UPDATE`、`ALGO_UPDATE`、`CONDITIONAL_ORDER_TRADE_UPDATE`
- **风控/配置类**：`MARGIN_CALL`、`ACCOUNT_CONFIG_UPDATE`
- **连接生命周期类**：`listenKeyExpired`、`eventStreamTerminated`
- **已下线**：`CONDITIONAL_ORDER_TRIGGER_REJECT`（2025-12-15 起并入 `ALGO_UPDATE`）

报告还分析了每种事件的幂等键建议维度（如 `outboundAccountPosition` 用 `u`、`executionReport` 用 `i + t`）和序号连续性策略（如 `executionReport`/`ORDER_TRADE_UPDATE` 的 z/l 累计量交叉校验），这些知识已沉淀到 `SEQUENCE-CONTINUITY-STRATEGY.md` §3/§5 和 `EVENT-TYPE-MAPPING.md` §5.2 作为未来参考。

当前缺少正式 ADR 记录用户数据流/私有流的排除理由和未来升级路径。

## 决策

**当前版本（v0.13.0）排除用户数据流（私有流）的采集和持久化。** binance-client 不连接用户数据流 WebSocket，binance-server 不持久化订单、成交、账户等私有事件。

## 理由

1. **模块定位**：binance 是 market_data ingestion 模块，职责为公有市场数据的采集、规范化、持久化与查询。交易下单、账户管理、私有交易策略明确列于 SPEC §3 排除范围和 goal/goal.md Non-Goals。
2. **凭证风险**：用户数据流需要 API Key + Secret 生成 `listenKey`，并定期 keepalive（30 分钟有效期）。引入凭证管理复杂度——包括密钥存储、轮换、泄露防护——与当前模块的「不持有生产凭证」边界（SPEC §3、§4 Runtime Boundary）冲突。
3. **职责边界**：订单/成交/账户管理属于**交易域**（execution domain），不属于**数据域**（market_data domain）。将私有交易事件混入 market_data 模块会违反 CONSTITUTION §1.1 的域职责分离原则。
4. **报告知识沉淀**：报告中的 19 种事件类型分类、幂等键建议维度和序号策略已沉淀到 `SEQUENCE-CONTINUITY-STRATEGY.md` §3/§5 和 `EVENT-TYPE-MAPPING.md` §5.2，作为未来实现的知识资产，不会因当前排除而丢失。

## 影响

- `binance-client` 不连接用户数据流 WebSocket（`wss://stream.binance.com:9443/ws/{listenKey}`）
- `binance-server` 不持久化订单/成交/账户事件，不建立对应 ClickHouse 表
- NATS subject 规约 `binance.market.{product_line}.{event_type}.v1` 不扩展到私有事件类型
- 下游需要用户数据（订单状态、成交回执、账户余额、仓位变动）的消费者需自行实现用户数据流采集，或使用独立模块

## 未来升级路径

如果未来需要用户数据流支持，升级路径为：

1. **新增独立 module**（推荐）：如 `module/binance_trading` 或 `module/binance_user_data`，承载用户数据流采集与持久化，与 market_data 模块完全解耦
2. **或在 binance 模块新增 client 子模块** `binance-client-userdata`，但需 ADR 评估是否违反 SPEC §3 排除范围——大概率需要 SPEC 版本升级和宪法审查
3. **参考报告知识资产**：实现时参考 `report/binance/20260704.md` §二 中的 19 种事件类型分析、幂等键建议维度和序号连续性策略，以及 `SEQUENCE-CONTINUITY-STRATEGY.md` §3/§5 和 `EVENT-TYPE-MAPPING.md` §5.2 中已沉淀的设计
4. **凭证管理 ADR**：需要独立 ADR 评估 API Key/Secret 与 listenKey 的存储、轮换、泄露防护方案，不可复用 market_data 模块的无凭证模型

## 关联

- SPEC §3 Scope（排除交易下单、账户管理、私有交易策略或生产凭证）
- SPEC §4 Runtime Boundary（`internal/client` 禁止暴露生产入口、配置不写入真实凭证）
- goal/goal.md Non-Goals（order execution、portfolio accounting、risk management）
- SEQUENCE-CONTINUITY-STRATEGY.md §3/§5（用户数据流序号策略参考）
- EVENT-TYPE-MAPPING.md §5.2（用户数据流幂等键维度参考）
- report/binance/20260704.md §二（用户数据流 19 种事件类型分析来源）
- ADR-010（CM→UM 迁移对用户数据流的影响，R-P1）
