# ADR-010: Platform Change Risk Register

> 状态：Accepted（监控中）
> 日期：2026-07-06
> 决策者：ZoneCNH architecture
> 来源：report/binance/20260704.md 平台变更提示
> 仓库归属：ZoneCNH 主仓 `module/binance/`

## 背景

Binance 平台在 2025-2026 年间发生多项架构变更，对 binance 模块的数据采集产生影响。本 ADR 登记报告 `report/binance/20260704.md` 中标注的三个平台变更风险，作为监控项跟踪，暂不触发 SPEC 或 runtime 代码修改。

## 风险登记

### R-P1: CM Perp → UM 架构迁移

- **变更时间**：2026-06-29 左右完成
- **影响范围**：CM 用户数据流事件与 UM 趋同，payload 用 `fs`:"UM"/"CM" 区分
- **对 binance 模块影响**：SPEC §6 仍保留 `cm_perp` 作为独立 product_line；公开行情流是否受影响待确认
- **当前状态**：监控中——报告标注带"?"，建议上线前对一遍最新 changelog
- **行动项**：无立即行动；若公开行情流也趋同，需评估是否合并 product_line 定义

### R-P2: Options 系统重构期

- **变更时间**：进行中（2026-07-06）
- **影响范围**：Options 事件名可能变更（官方公告在做 "Options Demo Trading" 升级）
- **对 binance 模块影响**：FR-030 Options Chain Raw Field Pass-through 的字段名可能需要更新
- **当前状态**：监控中
- **行动项**：定期检查 eapi changelog；重构完成后验证 parseOptionTicker 字段名

### R-P3: 现货 CSV 时间戳单位变更

- **变更时间**：2025-01-01 起
- **影响范围**：data.binance.vision 现货 CSV 文件时间戳从毫秒变为微秒（futures 不变）
- **对 binance 模块影响**：FR-016 Historical Backfill Planner 若使用官方 CSV 批量导入，需按日期分段处理时间戳单位
- **当前状态**：已记录——需在历史数据回填代码中处理
- **行动项**：runtime backfill 代码需对 2025-01-01 前后的现货数据分别处理时间戳单位
- **参考**：HISTORICAL-DATA-SYNC-STRATEGY.md §5.1

## 决策

记录为风险登记项，标注为"监控中"，不立即修改 SPEC 或 runtime 代码。

## 关联

- report/binance/20260704.md（来源）
- HISTORICAL-DATA-SYNC-STRATEGY.md §5.1（时间戳单位变更）
- EVENT-TYPE-MAPPING.md §6（平台变更备注）
- SPEC §6 Product Lines and Event Types
