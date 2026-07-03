# Changelog

## v1.0.1 - 2026-07-04

- 扩展 Yahoo 可采集数据类型：OHLCV、实时报价、基本面、分析师、期权持仓、新闻、多资产。
- 增补宏观核心指标缺口矩阵与必须补充数据源（FRED/BLS/EIA、World Bank/IMF/ECB/BIS、国家统计局/人行）。
- 新增 20 轮深度审查文档：`design/DEEP-ANALYSIS-20-PASS.md`。

## v1.0.0 - 2026-07-04

- 初始化 `module/yahoo/` 生产级文档骨架（goal/spec/matrix/plan/design/gate/schema）。
- 明确 Yahoo 宏观采集清单、更新频率、同步周期、历史回补起点与采集策略。
- 明确宏观分析补充项（跨源校验、事件冲击窗、revision alpha、质量因子）。
