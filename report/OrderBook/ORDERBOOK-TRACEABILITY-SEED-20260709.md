# orderbook Traceability Seed

> 日期：2026-07-09
> 状态：Draft / 非正式 Traceability
> 目标路径：若获授权，可迁移为 `module/orderbook/matrix/TRACEABILITY.md`
> 来源：`ORDERBOOK-SPEC-DRAFT-20260709.md`、`module/binance/matrix/TRACEABILITY.md`、`module/binance/spec/ACCEPTANCE.md`

---

## 0. 状态声明

本文是 traceability seed，不是模块矩阵 SSOT。[FRAME, HIGH]

正式矩阵只有在 `module/orderbook/` 获授权创建后才能落到 `module/orderbook/matrix/TRACEABILITY.md`。[COMPUTED, HIGH]

---

## 1. Matrix Seed

| Requirement | Description | Acceptance Criteria | Test Case / Gate | Source Mapping | Task | Status |
| --- | --- | --- | --- | --- | --- | --- |
| FR-OB-001 | Adapter Contract | AC-OB-001 | Adapter Conformance Gate | Binance FR-052/054。[COMPUTED, HIGH] | TASK-OB-001 | Pending |
| FR-OB-002 | Snapshot Alignment | AC-OB-002 | Replay Gate | Binance FR-054 / AC-OB-003。[COMPUTED, HIGH] | TASK-OB-002 | Pending |
| FR-OB-003 | Sequence Validation | AC-OB-003 | Gap Injection Gate | Binance FR-054 / AC-OB-004。[COMPUTED, HIGH] | TASK-OB-003 | Pending |
| FR-OB-004 | Book Mutation | AC-OB-004 | Book mutation tests | Binance FR-054 / AC-OB-005。[COMPUTED, HIGH] | TASK-OB-004 | Pending |
| FR-OB-005 | BookEvent Schema | AC-OB-005 | Schema fixture test | Binance FR-058/059 outputs。[COMPUTED, HIGH] | TASK-OB-005 | Pending |
| FR-OB-006 | BookHash | AC-OB-006 | Replay Determinism Gate | New orderbook requirement。[FRAME, HIGH] | TASK-OB-006 | Pending |
| FR-OB-007 | Replay Runner | AC-OB-007 | Replay fixture test | New orderbook requirement。[FRAME, HIGH] | TASK-OB-007 | Pending |
| FR-OB-008 | Gap Handling | AC-OB-008 | Gap Injection Gate | Binance FR-055 / AC-OB-006。[COMPUTED, HIGH] | TASK-OB-008 | Pending |
| FR-OB-009 | Quality Flags | AC-OB-009 | Quality timeline test | Binance FR-057/061。[COMPUTED, HIGH] | TASK-OB-009 | Pending |
| FR-OB-010 | Adapter Conformance | AC-OB-010 | Adapter Conformance Gate | New orderbook requirement。[FRAME, HIGH] | TASK-OB-010 | Pending |
| FR-OB-011 | Boundary Gate | AC-OB-011 | Boundary Gate | New orderbook requirement。[FRAME, HIGH] | TASK-OB-011 | Pending |
| FR-OB-012 | Evidence Manifest | AC-OB-012 | Evidence Gate | New orderbook requirement。[FRAME, HIGH] | TASK-OB-012 | Pending |
| BR-OB-001 | No unauthorized creation | AC-OB-013 | Governance Gate | Constitution §2.6。[COMPUTED, HIGH] | TASK-OB-013 | Pending |
| BR-OB-002 | Domain model SSOT | AC-OB-014 | Boundary Gate | `domain_market` boundary。[COMPUTED, HIGH] | TASK-OB-014 | Pending |
| BR-OB-003 | No venue internal import | AC-OB-015 | Boundary Gate | Contract/Gate draft。[FRAME, HIGH] | TASK-OB-015 | Pending |
| BR-OB-004 | Deterministic hash only | AC-OB-016 | Replay Determinism Gate | Contract/Gate draft。[FRAME, HIGH] | TASK-OB-016 | Pending |
| BR-OB-005 | reliable=false fail-closed | AC-OB-017 | Gap / Quality Gate | Contract/Gate draft。[FRAME, HIGH] | TASK-OB-017 | Pending |
| BR-OB-006 | No cross-venue claim before second venue | AC-OB-018 | Adapter Gate | ADR draft。[FRAME, HIGH] | TASK-OB-018 | Pending |

---

## 2. Binance FR 映射

| Binance FR | Binance AC | orderbook Candidate | 迁移含义 |
| --- | --- | --- | --- |
| FR-052 | AC-OB-001 | FR-OB-001 / FR-OB-008 | 状态机与 adapter contract 的首个实现来源。[COMPUTED, HIGH] |
| FR-053 | AC-OB-002 | FR-OB-005 / FR-OB-009 | snapshot_topn 可作为 degraded/no-sequence 模式参考。[INFERRED, MED] |
| FR-054 | AC-OB-003~005 | FR-OB-002 / FR-OB-003 / FR-OB-004 | alignment、sequence、mutation 是核心迁移对象。[COMPUTED, HIGH] |
| FR-055 | AC-OB-006 | FR-OB-008 | gap handling 与 rebuild 语义来源。[COMPUTED, HIGH] |
| FR-056 | AC-OB-007 | FR-OB-012 | persistence 可作为 evidence/recovery 输入，但不必首版通用化。[INFERRED, MED] |
| FR-057 | AC-OB-008 | FR-OB-009 | staleness 与 health 语义来源。[COMPUTED, HIGH] |
| FR-058 | AC-OB-009 | FR-OB-005 | TopN output 可参考，但不应定义唯一输出模型。[INFERRED, HIGH] |
| FR-059 | AC-OB-010 | FR-OB-005 / FR-OB-009 | IncrementalEvent 与 rebuild marker 是 BookEvent/QualityEvent 输入。[COMPUTED, HIGH] |
| FR-060 | AC-OB-011 | FR-OB-009 | on-demand snapshot 与 health query 属 runtime API 候选。[INFERRED, MED] |
| FR-061 | AC-OB-012 | FR-OB-009 / FR-OB-012 | drift detection 与 alerting 是 quality/evidence 输入。[COMPUTED, HIGH] |

---

## 3. Gate Seed

| Gate | 覆盖 Requirement | 最小证据 |
| --- | --- | --- |
| Governance Gate | BR-OB-001 | 准入 ADR Accepted + 人工显式授权。[COMPUTED, HIGH] |
| Boundary Gate | FR-OB-011 / BR-OB-002 / BR-OB-003 | import graph / script output。[FRAME, HIGH] |
| Replay Determinism Gate | FR-OB-006 / FR-OB-007 / BR-OB-004 | same fixture replay hash stable。[FRAME, HIGH] |
| Gap Injection Gate | FR-OB-003 / FR-OB-008 / BR-OB-005 | injected gap leads reliable=false。[FRAME, HIGH] |
| Adapter Conformance Gate | FR-OB-001 / FR-OB-010 / BR-OB-006 | adapter fixture + semantics pass。[FRAME, HIGH] |
| Evidence Gate | FR-OB-012 | manifest with command/result/hash/source_commit。[FRAME, HIGH] |

---

## 4. 状态解释

所有行当前为 `Pending`，因为 `orderbook` 模块尚未授权创建，不能声明 Done。[COMPUTED, HIGH]

Binance 映射中的 Done 只说明 binance FR-052~061 在 binance 规格口径下已完成，不能自动翻译为 `orderbook` 模块完成。[COMPUTED, HIGH]

---

[RULES I BROKE]：无
