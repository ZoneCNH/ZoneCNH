# Changelog — treasury

> 版本事实源：`spec/SPEC.md` Spec-Version · Release 事实源：GitHub Release

## [Unreleased]

- 规格从 Draft 占位升级为生产目标口径（v0.2.0）：
  - 显式声明 `module/binance` 为 C/S 样板参考
  - 补齐四子模块采集清单（yield/auction/fiscal/tic）
  - 补齐 Fiscal Data API 分类映射（Debt/Interest/Exchange/Statements/Securities/Revenue/TIC）
  - 明确定时更新频率、同步周期、历史数据同步启点
  - 补充增量/全量重同步策略、ET 16:00 发布窗口与单轮同步 ≤30min 目标
  - 明确 raw-first + 双总线 + 七类介质持久化采集策略
  - 新增宏观分析补充项（宏观联动、可持续性、全球比较、高频与数据治理）
