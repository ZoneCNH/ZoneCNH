# treasury 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-30
- Layer: 数据域 · 宏观（C/S 采集器）
- Version: v0.1.0-draft
- Repository: [github.com/ZoneCNH/treasury](https://github.com/ZoneCNH/treasury)
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/contracts`, `module/domain_macro`, `module/fred`

> 占位规格（Draft）。treasury 是美国国债/财政数据 C/S 采集器，与 fred 同属宏观数据域。架构类型为 C/S Module（参考 `module/data_cs_module/`）。完整 23 节规格待进入 Spec→Code 管线时补齐。

---

## 1. 摘要

`module/treasury` 是美国国债与财政数据 C/S 采集器，直接实现 `contracts.MacroDataProvider` 接口。采集美国财政部（Treasury Direct / Daily Treasury Par Yield Curve Rates / ICSID 等）公开数据源，归一化为 `MacroPoint`（复用 `domain_macro`），下游通过接口直接消费。

```text
US Treasury / Treasury Direct / Daily Yield Curve
  ↓
module/treasury (client/server) → 实现 MacroDataProvider
  ↓
macro_data / factor_engine (直接消费)
```

---

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 国债收益率曲线、财政赤字、TIC 数据采集与归一化、`MacroDataProvider` 接口实现、数据时效性管理 |
| Depends on | `module/contracts`（`MacroDataProvider` 接口 + DTO）、`module/domain_macro`（`MacroPoint` 语义）、基座层（kernel/configx/observex/resiliencx） |
| Consumed by | `module/macro_data`（聚合层）、`module/factor_engine`（宏观因子）、`module/factor_eval`（评估） |
| Excludes | 宏观信号生成（→ factor_engine）、数据持久化（treasury 只做采集+归一化，不存储历史）、支付/认证 |

---

## 3. 数据源（占位 — 待补齐）

| 数据源 | 数据类型 | 更新频率 | 免费/付费 |
| --- | --- | --- | --- |
| US Treasury Daily Par Yield Curve | 国债收益率曲线（1M/3M/6M/1Y/2Y/.../30Y） | 每交易日 | 免费 |
| Treasury Direct | 国债拍卖结果、发行规模 | 按拍卖日程 | 免费 |
| TIC (Treasury International Capital) | 跨境资本流动 | 月度 | 免费 |

> 完整数据源、FR、WHEN/THEN 待进入 Spec→Code 管线时按 [`data_cs_module/SPEC-TEMPLATE.md`](../data_cs_module/SPEC-TEMPLATE.md) 补齐。

---

## 4. 架构类型

C/S Module（数据域采集器），遵循 [`module/data_cs_module/README.md`](../data_cs_module/README.md) 标准化索引：

```text
treasury/
├── cmd/treasury-server/main.go    # bootstrap.Build() 独立进程
├── internal/client/               # 数据采集
├── internal/server/               # 数据服务
├── internal/wire/                 # 进程间 wire contract
├── pkg/treasuryx/                 # 公开 adapter
└── go.mod
```

---

## Open Questions

- [ ] treasury 与 fred 的职责边界是否完全清晰（fred=FRED 宏观经济、treasury=国债财政）？
- [ ] 是否复用 fred 的 C/S 模板，还是独立实现？
- [ ] 完整 23 节规格进入 Spec→Code 管线的优先级？
