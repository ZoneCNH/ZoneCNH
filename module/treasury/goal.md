# treasury Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `treasury` |
| 层级 | 数据域 · 宏观（C/S 采集器） |
| 仓库 | <https://github.com/ZoneCNH/treasury> |
| 当前版本 | v0.1.0-draft |
| 目标版本 | v0.1.0 |
| 状态 | Draft — 占位规格，完整 23 节 SPEC 待进入 Spec-Code 管线时补齐 |
| 最后更新 | 2026-06-29 |

## 目标

`treasury` 是美国国债与财政数据 C/S 采集器，直接实现 `contracts.MacroDataProvider` 接口。采集美国财政部（Treasury Direct / Daily Treasury Par Yield Curve Rates / TIC 等）公开数据源，归一化为 `MacroPoint`（复用 `domain_macro`），下游通过接口直接消费。

## 非目标

- 不实现宏观信号生成（-> factor_engine）
- 不实现数据持久化（只做采集+归一化）
- 不处理支付/认证

## 架构类型

C/S Module（数据域采集器），遵循 `module/data_cs_module/` 标准化模板：

```text
treasury/
├── cmd/treasury-server/main.go
├── internal/client/
├── internal/server/
├── internal/wire/
├── pkg/treasuryx/
└── go.mod
```

## 数据源

| 数据源 | 类型 | 更新频率 |
| --- | --- | --- |
| US Treasury Daily Par Yield Curve | 国债收益率曲线 | 每交易日 |
| Treasury Direct | 国债拍卖结果 | 按拍卖日程 |
| TIC | 跨境资本流动 | 月度 |

## 当前阻塞

| 优先级 | 阻塞项 | 处理方向 |
| --- | --- | --- |
| P0 | SPEC 仍为 Draft 占位规格 | 按 data_cs_module/SPEC-TEMPLATE.md 补齐 23 节 |
| P1 | treasury 与 fred 职责边界 | 明确 fred=FRED 宏观、treasury=国债财政 |
| P2 | 是否复用 fred 的 C/S 模板 | 评估独立实现 vs 复用 |
