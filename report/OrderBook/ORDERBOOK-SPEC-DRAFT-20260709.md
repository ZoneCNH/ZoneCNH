# orderbook SPEC 草案

> 日期：2026-07-09
> 状态：Draft / 非正式 SPEC
> 目标路径：若获授权，可迁移为 `module/orderbook/spec/SPEC.md`
> 约束：本文不创建 `module/orderbook/`，不登记 `module/registry.yaml`，不创建 runtime repo
> 来源：`knowledge/OrderBook.md`、binance FR-052~061、`ORDERBOOK-CONTRACT-GATE-DRAFT-20260709.md`

---

## 0. 状态声明

本文是规格草案，不是 Approved SPEC。[FRAME, HIGH]

本文只定义 `orderbook` 模块候选职责和验收要求，不授权任何创建动作。[COMPUTED, HIGH]

正式 SPEC 必须在准入 ADR Accepted、双闸门授权齐备后才能写入 `module/orderbook/`。[COMPUTED, HIGH]

---

## 1. 模块定位

`orderbook` 的候选定位是跨 venue 订单簿事实链 contract 与 runtime core。[FRAME, HIGH]

该模块应把 raw snapshot/diff 输入转化为可验证、可重放、可质量标注的 BookEvent / BookState / QualityTimeline。[FRAME, HIGH]

该模块不应承担交易所私有协议、策略决策、下单、账户流、alpha 研究或市场状态解释。[FRAME, HIGH]

---

## 2. 目标

| 目标 | 描述 |
| --- | --- |
| G-OB-001 | 统一 snapshot + diff 对齐和 sequence validation contract。[FRAME, HIGH] |
| G-OB-002 | 统一 BookEvent / GapEvent / QualityEvent schema。[FRAME, HIGH] |
| G-OB-003 | 提供 deterministic BookHash 和 replay gate。[FRAME, HIGH] |
| G-OB-004 | 提供 adapter conformance gate，避免 venue 语义漂移。[FRAME, HIGH] |
| G-OB-005 | 为 binance 当前 OrderBook runtime 迁移提供可审 contract。[FRAME, HIGH] |

---

## 3. 非目标

| 非目标 | 委派方 |
| --- | --- |
| Binance / OKX / Bybit 私有 REST/WS 协议实现。[FRAME, HIGH] | `binance`、未来 venue adapter 模块 |
| canonical market domain model。[COMPUTED, HIGH] | `domain_market` |
| venue capability 和 exchange error SPI。[COMPUTED, HIGH] | `domain_exchange` |
| 行情采集白名单 server API。[COMPUTED, HIGH] | 具体 venue server/control plane |
| 因子研究与 alpha 评价。[INFERRED, HIGH] | `factor_engine` |
| 市场状态解释。[INFERRED, HIGH] | `market_regime` 或后续专用模块 |
| 下单、订单生命周期、账户私有流。[INFERRED, HIGH] | `execution` / `orderx` / venue 私有流模块 |

---

## 4. Functional Requirements

| FR | 名称 | 说明 |
| --- | --- | --- |
| FR-OB-001 | Adapter Contract | 定义 SnapshotLoader、DiffSubscriber、SequencePolicy、ExchangeSemantics。[FRAME, HIGH] |
| FR-OB-002 | Snapshot Alignment | 支持 snapshot 与 buffered diff 对齐，并产生可审 AlignResult。[FRAME, HIGH] |
| FR-OB-003 | Sequence Validation | 支持 venue-specific continuity rule，失败时进入 gap/rebuild 语义。[FRAME, HIGH] |
| FR-OB-004 | Book Mutation | 支持 bid/ask level add/update/remove，`qty=0` 语义由 ExchangeSemantics 声明。[FRAME, HIGH] |
| FR-OB-005 | BookEvent Schema | 输出 BookEvent、GapEvent、QualityEvent，字段带 schema_version。[FRAME, HIGH] |
| FR-OB-006 | BookHash | 对 deterministic book state 生成稳定 hash。[FRAME, HIGH] |
| FR-OB-007 | Replay Runner | 从 fixture 重放 snapshot + diff 并产出 BookHash 与 QualityTimeline。[FRAME, HIGH] |
| FR-OB-008 | Gap Handling | 对 missing、duplicated、out-of-order、broken prev sequence 提供降级和恢复语义。[FRAME, HIGH] |
| FR-OB-009 | Quality Flags | 输出 reliable、stale、gap_detected、degraded、snapshot_drift 等质量标记。[FRAME, HIGH] |
| FR-OB-010 | Adapter Conformance | 每个 adapter 必须提交 semantics、snapshot、diff、gap 和 expected hash fixture。[FRAME, HIGH] |
| FR-OB-011 | Boundary Gate | 阻断通用模块 import venue runtime internal 包。[FRAME, HIGH] |
| FR-OB-012 | Evidence Manifest | 每次 gate 通过必须产出 manifest，包含 fixture、命令、hash 和源 commit。[FRAME, HIGH] |

---

## 5. Business / Engineering Rules

| BR | 规则 | 验证 |
| --- | --- | --- |
| BR-OB-001 | 未经双闸门授权不得创建 `module/orderbook/` 或 runtime repo。[COMPUTED, HIGH] | Governance Gate |
| BR-OB-002 | `domain_market` 是 market model SSOT，`orderbook` 不重复定义 canonical model。[FRAME, HIGH] | Boundary Gate |
| BR-OB-003 | `orderbook` 不依赖 `binance/internal`、`okx/internal` 或消费方 internal 包。[FRAME, HIGH] | Boundary Gate |
| BR-OB-004 | BookHash 不得包含 wall clock、local receive time、map iteration order 或随机数。[COMMON, HIGH] | Replay Gate |
| BR-OB-005 | `reliable=false` 必须阻断默认执行态消费。[FRAME, HIGH] | Gap / Quality Gate |
| BR-OB-006 | 第二 venue conformance 通过前不得宣称跨 venue 平台完成。[INFERRED, HIGH] | Adapter Gate |

---

## 6. Acceptance Criteria

| AC | 关联 | 验收内容 |
| --- | --- | --- |
| AC-OB-001 | FR-OB-001 | Adapter Contract 能表达 Binance spot `U/u` 与 futures `pu/u` 语义。[FRAME, HIGH] |
| AC-OB-002 | FR-OB-002 | 同一 snapshot + diff fixture 能确定性完成 alignment。[FRAME, HIGH] |
| AC-OB-003 | FR-OB-003 | sequence break 触发 gap/rebuild，且 downstream reliable=false。[FRAME, HIGH] |
| AC-OB-004 | FR-OB-004 | `qty=0` 删除价位语义可由 semantics 声明并测试。[FRAME, HIGH] |
| AC-OB-005 | FR-OB-005 | BookEvent 最小字段齐备，schema_version 可审。[FRAME, HIGH] |
| AC-OB-006 | FR-OB-006 | 同一 fixture replay 100 次 BookHash 一致。[FRAME, HIGH] |
| AC-OB-007 | FR-OB-007 | ReplayRunner 输出 BookState、BookHash、QualityTimeline。[FRAME, HIGH] |
| AC-OB-008 | FR-OB-008 | missing/duplicated/out-of-order diff 均有显式结果。[FRAME, HIGH] |
| AC-OB-009 | FR-OB-009 | stale、gap、degraded、drift 的质量转换可测试。[FRAME, HIGH] |
| AC-OB-010 | FR-OB-010 | Binance adapter fixture 可通过 conformance gate。[FRAME, HIGH] |
| AC-OB-011 | FR-OB-011 | Boundary Gate 阻断禁止 import。[FRAME, HIGH] |
| AC-OB-012 | FR-OB-012 | Evidence manifest 包含命令、结果、fixture_set、hash 和 source_commit。[FRAME, HIGH] |

---

## 7. 依赖草案

| 依赖 | 用途 | 首版建议 |
| --- | --- | --- |
| `decimalx` | deterministic decimal canonicalization。[COMMON, HIGH] | 必需 |
| `domain_market` | canonical model 与 quality 语义对齐。[COMPUTED, HIGH] | 必需 |
| `domain_exchange` | venue semantics / adapter SPI 对齐。[COMPUTED, HIGH] | 必需 |
| `observex` | metrics / logs / trace contract。[INFERRED, MED] | 可选 |
| `resiliencx` | retry/backoff/circuit breaker contract。[INFERRED, MED] | 可选 |
| `testkitx` | fixture 和 conformance 测试。[INFERRED, MED] | 必需或测试依赖 |

首版不建议直接依赖 `factor_engine`、`execution`、`orderx`、`natsx`、`kafkax`、`clickhousex` 或 `ossx`。[INFERRED, HIGH]

---

## 8. 验证命令草案

```bash
go test ./pkg/adapter ./pkg/builder ./pkg/event ./pkg/replay ./pkg/quality -count=1
go test ./test/conformance -count=1
bash scripts/boundary-gates.sh
bash scripts/replay-determinism-gate.sh
bash scripts/gap-injection-gate.sh
```

上述命令是未来 runtime repo 草案命令，不代表当前仓库已有这些路径。[FRAME, HIGH]

---

## 9. Open Questions

| 问题 | 阻断 |
| --- | --- |
| arch_type 选 `contract`、`library` 还是 `independent_process`？[INFERRED, HIGH] | 阻断正式准入 ADR |
| 命名模式是否接受“业务域 runtime platform”？[COMPUTED, HIGH] | 阻断命名审批 |
| 第二 venue POC 是 OKX 还是 Bybit？[GUESS, LOW] | 阻断跨 venue claim |
| BookHash canonical decimal 是否完全委托 `decimalx`？[INFERRED, HIGH] | 阻断 Replay Gate |
| options depth 是 postponed 还是 not_applicable？[INFERRED, HIGH] | 阻断 binance Phase 1 close |

---

[RULES I BROKE]：无
