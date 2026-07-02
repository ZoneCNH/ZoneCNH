> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [← 上一节](19-cri.md) · [↑ 目录](README.md)

---

## 附录 A：模块清单

| 层级           | 模块          | 规格                                   | 仓库                                                      |
| -------------- | ------------- | -------------------------------------- | --------------------------------------------------------- |
| L0 原语        | kernel        | [SPEC](./module/kernel/spec/SPEC.md)        | [kernel](https://github.com/ZoneCNH/kernel)               |
| L1 运行时      | configx       | [SPEC](./module/configx/spec/SPEC.md)       | [configx](https://github.com/ZoneCNH/configx)             |
| L1 运行时      | observex      | [SPEC](./module/observex/spec/SPEC.md)      | [observex](https://github.com/ZoneCNH/observex)           |
| L1 运行时      | resiliencx    | [SPEC](./module/resiliencx/spec/SPEC.md)    | [resiliencx](https://github.com/ZoneCNH/resiliencx)       |
| L1 运行时      | schedulex     | [SPEC](./module/schedulex/spec/SPEC.md)     | [schedulex](https://github.com/ZoneCNH/schedulex)         |
| L1 test-only   | testkitx      | [SPEC](./module/testkitx/spec/SPEC.md)      | [testkitx](https://github.com/ZoneCNH/testkitx)           |
| 标准源         | xlib_standard | [SPEC](./module/xlib_standard/spec/SPEC.md) | [xlib_standard](https://github.com/ZoneCNH/xlib_standard) |
| 门禁           | xlibgate      | [SPEC](./module/xlibgate/spec/SPEC.md)      | [xlibgate](https://github.com/ZoneCNH/xlibgate)           |
| 门禁           | xlib_harness  | [SPEC](./module/xlib_harness/spec/SPEC.md)  | [xlib_harness](https://github.com/ZoneCNH/xlib_harness)   |
| 门禁           | xlib_evidence | [SPEC](./module/xlib_evidence/spec/SPEC.md) | [xlib_evidence](https://github.com/ZoneCNH/xlib_evidence) |
| 存储扩展       | redisx        | [SPEC](./module/redisx/spec/SPEC.md)        | [redisx](https://github.com/ZoneCNH/redisx)               |
| 存储扩展       | kafkax        | [SPEC](./module/kafkax/spec/SPEC.md)        | [kafkax](https://github.com/ZoneCNH/kafkax)               |
| 存储扩展       | natsx         | [SPEC](./module/natsx/spec/SPEC.md)         | [natsx](https://github.com/ZoneCNH/natsx)                 |
| 存储扩展       | postgresx     | [SPEC](./module/postgresx/spec/SPEC.md)     | [postgresx](https://github.com/ZoneCNH/postgresx)         |
| 存储扩展       | taosx         | [SPEC](./module/taosx/spec/SPEC.md)         | [taosx](https://github.com/ZoneCNH/taosx)                 |
| 存储扩展       | ossx          | [SPEC](./module/ossx/spec/SPEC.md)          | [ossx](https://github.com/ZoneCNH/ossx)                   |
| 存储扩展       | clickhousex   | [SPEC](./module/clickhousex/spec/SPEC.md)   | [clickhousex](https://github.com/ZoneCNH/clickhousex)     |
| 契约           | contracts     | [SPEC](./module/contracts/spec/SPEC.md)     | [contracts](https://github.com/ZoneCNH/contracts)         |
| 契约/传输      | transportx    | [SPEC](./module/transportx/spec/SPEC.md)    | [transportx](https://github.com/ZoneCNH/transportx)       |
| 领域共享       | domainx       | [SPEC](./module/domainx/spec/SPEC.md)       | [domainx](https://github.com/ZoneCNH/domainx)             |
| 组合根         | x.go          | [SPEC](./module/xgo/spec/SPEC.md)           | [x.go](https://github.com/ZoneCNH/x.go)                   |

## 附录 B：与 CLAUDE.md 的关系

`CLAUDE.md` 是 Claude Code 的工作指南，规定仓库级别的操作约定（文档同步、提交格式、安全红线）。本宪法是系统级别的治理文件，规定模块实现和交付管线的技术标准。

两者互补：

- `CLAUDE.md` 管"怎么编辑这个仓库"
- 本宪法管"怎么实现模块"（§1-§14）和"怎么交付功能"（§15-§19）

当两者冲突时，`CLAUDE.md` 中的安全条款（不提交凭证等）优先；技术条款以本宪法为准。
````


## 附录：L2.5 领域共享 v1.0.0 收口边界

截至 2026-06-15，L2.5 领域共享层按以下五个模块收口 v1.0.0 执行计划：

| 模块 | 归属边界 | 发布依赖 |
| --- | --- | --- |
| `decimalx` | Decimal、Money、Currency、rounding/context、JSON/SQL 数值边界 | 第一优先级 |
| `domain_market` | Tick、Quote、Bar、OrderBook、Instrument、Funding、OpenInterest、LongShortRatio、MarketDataQuality | `decimalx` |
| `domain_macro` | MacroPoint、MacroInformationSet、revision、freshness、no-lookahead visibility | `decimalx` 精度 ADR |
| `domainx` | Order、Trade、Position、Portfolio、ExecutionReport、OrderSide、OrderType、OrderState | `decimalx`，并与 `domain_market` 边界对齐 |
| `domain_exchange` | Exchange SPI、VenueCapability、RateLimitPolicy、ExchangeError、Registry | `decimalx`、`domain_market`、`domainx` |

L2.5 公共规则：公开金融数值字段不得使用 public `float64` 表示价格、数量、金额、费率或名义价值；领域共享层不得暴露 transport DTO、provider 原始响应、HTTP/WS/Kafka/TDengine 细节或数据库 ORM tag；跨模块重复语义必须收敛到唯一 SSOT。
