# 数据 C/S 模块治理模板

- Template-Version: v1.0.0
- Last-Updated: 2026-06-27
- Scope: `module/data_cs_module/` 新增数据源模块
- Source Pattern: binance governance docs + runtime boundary-gates practice

> 使用方式：复制本文件到 `module/{module}/gate/GOVERNANCE.md` 或拆分到 `gate/RULES.md`、`gate/BOUNDARY-GATES.md`、`spec/NAMING.md`。复制后把 `{module}`、`{DATA_SOURCE}`、`{domain}`、`{product_lines}` 替换为目标模块语义。

## §0 模块身份

| 字段 | 值 |
| --- | --- |
| Module | `{module}` |
| Data Source | `{DATA_SOURCE}` |
| Domain | `{market_data | macro_data}` |
| Architecture | C/S Module |
| Governance Level | L1 / L2 / L3 |
| Runtime Repo | `github.com/ZoneCNH/{module}` |
| Spec Root | `module/{module}/spec/SPEC.md` |
| Runtime Root | `/home/{module}` |

## §1 可复用规则层

| 层 | 是否可复用 | 说明 |
| --- | --- | --- |
| R1 边界声明 | 模块定制 | 每个数据源的拥有/不拥有边界不同，必须重写 |
| R2 命名矩阵 | 模块定制 | product line、instrument subtype、event type 由数据源决定 |
| R3 client/server import boundary | 可复用 | client 不 import server；server 不 import client |
| R4 shared package boundary | 可复用 | `internal/cs` 只放共享类型，不承载 runtime 依赖 |
| R5 transport contract boundary | 可复用 | wire/proto/contract 不由数据源模块私有定义 |
| R6 storage ownership boundary | 可复用 | 数据源模块只拥有采集与摄入，不拥有 canonical domain model |
| R7 downstream dispatch boundary | 可复用 | 只通过明确 port 交付到 downstream |
| R8 status/evidence split | 可复用 | Code-State 与 Evidence-State 分离 |
| R9 document existence | 可复用 | README / CHANGELOG / gate / matrix / evidence 索引存在 |
| R10 runtime gate parity | 可复用 | 文档 gate 与 runtime script gate 保持同源 |
| R11 rate/backfill model | 模块定制 | 交易所、宏观 API 的 quota 模型不同 |
| R12 gap/data-quality model | 模块定制 | 事件序列、时间序列、批量指标的 gap 判定不同 |

## §2 boundary gates 模板

每个模块必须声明自己的 gate 数量，并保持 `gate/BOUNDARY-GATES.md` 与 runtime `scripts/boundary-gates.sh` 一致。不要从 binance 固定复制 "12 gates" 或 "13 gates"；binance 文档与 runtime gate 数量会随版本演进。

| Gate | 检查 | 默认级别 | 说明 |
| --- | --- | --- | --- |
| G1 | no legacy module/package name | 硬 | 迁移模块必须保留 |
| G2 | client does not import server | 硬 | C/S 模块默认启用 |
| G3 | server does not import client | 硬 | C/S 模块默认启用 |
| G4 | shared package has no runtime ownership | 硬 | `internal/cs` / shared DTO |
| G5 | no in-process shortcut between client/server | 硬 | 防止绕过契约 |
| G6 | transport contracts externalized | 硬 | proto/wire 由 contracts 或等价 SSOT 拥有 |
| G7 | storage ownership limited | 硬 | 禁止吞并 canonical storage/domain ownership |
| G8 | downstream dispatch through declared ports | 硬 | Kafka/NATS/gRPC/HTTP adapter 均需显式 |
| G9 | product-line naming matrix complete | 硬 | 行情与宏观可替换为 data-dimension matrix |
| G10 | config/env documented and validated | 硬 | runtime env 与 spec §11 对齐 |
| G11 | evidence-state ledger exists | 硬 | Code/Evidence 双态账本 |
| G12 | external integration gated | 软/硬 | L3 前必须硬化 |

## §3 NAMING.md 结构

```text
module/{module}/spec/NAMING.md
├── §1 Scope
├── §2 Product Lines / Data Dimensions
├── §3 Instrument / Dataset Identity
├── §4 Event / Record Types
├── §5 Canonical Key Shape
├── §6 Config Keys
├── §7 Metric Names
├── §8 Topic / Stream Names
├── §9 Error Codes
├── §10 Deprecated Aliases
└── §11 Migration Rules
```

## §4 RULES.md 结构

```text
module/{module}/gate/RULES.md
├── R1 Boundary Ownership
├── R2 Naming Symmetry
├── R3 Client/Server Import Boundary
├── R4 Shared Types Boundary
├── R5 Transport Contract Boundary
├── R6 Storage Ownership Boundary
├── R7 Downstream Dispatch Boundary
├── R8 Code-State / Evidence-State Split
├── R9 Required Documents
├── R10 Runtime Gate Parity
├── R11 Source-Specific Quota / Backfill Model
└── R12 Source-Specific Gap / Quality Model
```

## §5 L1/L2/L3 接线

| 等级 | 模板最低要求 |
| --- | --- |
| L1 | 填写 §0、R1、R2、NAMING §1-§5；不得声明 Evidence-Done |
| L2 | 填写全部 R1-R12；提供 runtime 编译/测试证据；维护 Code/Evidence 双态 |
| L3 | L2 + live integration、external E2E、soak/release/rollback evidence |

## §6 issue 关闭规则

1. 文档/模板缺口 issue：模板落地、索引更新、检查通过后可关闭。
2. runtime Code-State issue：必须有代码锚点与测试证据。
3. Evidence-State issue：必须有归档证据；live/production/external 证据缺失时不得关闭。
