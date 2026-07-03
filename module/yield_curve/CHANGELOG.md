# Changelog — yield_curve

> 版本事实源：`spec/SPEC.md` Spec-Version · Release 事实源：GitHub Release

## [Unreleased]

- 初始化 `module/yield_curve` 生产级规格（v0.1.0）：
  - 定义 BoE Anderson-Sleath 收益率曲线采集清单与五类曲线覆盖
  - 补齐定时更新频率、同步周期、缓存策略、历史起点
  - 明确 daily/月频语义（最新月份日度 vs archive 月末）与 archive 稳定性
  - 补齐增量/全量/重同步策略与公开 API 采集路径
  - 对齐独立 C/S 模块、共享基座、`domain_macro` 与七类持久化边界
  - 增补宏观分析扩展项（货币政策、跨市场、衍生指标、数据治理、货币信贷/住房/汇率）
