# pe_data Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `pe_data` |
| 层级 | 数据域 · 另类数据（PE 数据采集模块） |
| 仓库 | <https://github.com/ZoneCNH/pe_data> |
| 当前版本 | v0.1.0-draft |
| 目标版本 | v0.1.0 |
| 状态 | Draft — SPEC 已定义 FR-001~005 + BR-001~004 |
| 最后更新 | 2026-06-29 |

## 目标

`pe_data` 是 PE 另类数据采集模块，直接实现 `contracts.AlternativeDataProvider` 接口。爬取 SEC EDGAR 13F / Form 4 / 机构持仓变化等公开数据源，归一化为 `PEvent`，下游（signal_factory / backtestx）通过接口直接消费。

## 非目标

- 不实现 PE 信号生成（-> signal_factory）
- 不实现 PE 策略（-> strategyx）
- 不实现数据持久化（pe_data 只做采集+归一化）
- 不处理支付/认证（-> 配置密钥管理）
- 不替代 alternative_data 聚合层角色

## 数据源

| 数据源 | 类型 | 更新频率 | 状态 |
| --- | --- | --- | --- |
| SEC EDGAR 13F | 机构季度持仓 | 季度+45天 | 免费 |
| Form 4 | 内部人交易 | 交易后2天 | 免费 |
| WhaleWisdom | 13F聚合+基金跟踪 | 每日 | 免费层 |
| OpenInsider | 内部人交易聚合 | 每日 | 免费 |
| Preqin/PitchBook | PE/VC基金表现 | 季度 | 付费 |

## 当前阻塞

| 优先级 | 阻塞项 | 处理方向 |
| --- | --- | --- |
| P0 | SPEC 仅定义 FR-001~005 + BR-001~004 | 补齐完整 FR/BR/NFR/AC/TC |
| P1 | 与 alternative_data 的边界未定 | 明确子模块 vs 独立采集器角色 |
| P2 | 付费数据源（Preqin/PitchBook）接入 | 先用免费源验证信号有效性 |
