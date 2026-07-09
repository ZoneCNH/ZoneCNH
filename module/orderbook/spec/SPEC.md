# orderbook SPEC

- Status: Approved
- Spec-Version: v0.1.0
- Last-Updated: 2026-07-09
- Layer: business data library
- Arch-Type: library
- Source Goal: `GOAL-20260709-001`
- Runtime Path: `/home/workspace/orderbook`

---

## 1. Summary

`orderbook` 提供跨 venue 的订单簿事实链 runtime core，将 snapshot + diff 输入转换为可验证、可重放、可质量标注的 BookState、BookHash、GapEvent 和 QualityTimeline。[FRAME, HIGH]

## 2. Boundary

| Owns | Does Not Own |
| --- | --- |
| Adapter contract、SequencePolicy、ExchangeSemantics。[FRAME, HIGH] | 交易所私有 REST/WS client。[FRAME, HIGH] |
| Book mutation engine、BookHash、ReplayRunner。[FRAME, HIGH] | `domain_market` canonical model。[COMPUTED, HIGH] |
| Gap/Quality/Conformance/Boundary gate。[FRAME, HIGH] | 策略、alpha、执行、账户和订单生命周期。[INFERRED, HIGH] |

## 3. Functional Requirements

| ID | Requirement |
| --- | --- |
| FR-OB-001 | 定义 SnapshotLoader、DiffSubscriber、SequencePolicy、ExchangeSemantics adapter contract。[FRAME, HIGH] |
| FR-OB-002 | 支持 snapshot 与 buffered diff 的 deterministic alignment。[FRAME, HIGH] |
| FR-OB-003 | 支持 venue-specific sequence validation，失败时产生 gap/rebuild quality。[FRAME, HIGH] |
| FR-OB-004 | 支持 bid/ask level add/update/remove，`qty=0` 删除语义由 ExchangeSemantics 声明。[FRAME, HIGH] |
| FR-OB-005 | 输出 BookEvent、GapEvent、QualityEvent，带 schema_version。[FRAME, HIGH] |
| FR-OB-006 | 对 deterministic book state 生成稳定 BookHash。[FRAME, HIGH] |
| FR-OB-007 | ReplayRunner 从 fixture 重放 snapshot + diff 并输出 BookHash 与 QualityTimeline。[FRAME, HIGH] |
| FR-OB-008 | missing、duplicated、out-of-order、broken prev sequence 均有显式结果。[FRAME, HIGH] |
| FR-OB-009 | 输出 reliable、stale、gap_detected、degraded、snapshot_drift 等质量标记。[FRAME, HIGH] |
| FR-OB-010 | Adapter conformance fixture 可验证 semantics、snapshot、diff、gap 和 expected hash。[FRAME, HIGH] |
| FR-OB-011 | Boundary gate 阻断 venue runtime internal import。[FRAME, HIGH] |
| FR-OB-012 | Evidence manifest 记录命令、结果、hash、fixture_set 和 source_commit。[FRAME, HIGH] |

## 4. Business Rules

| ID | Rule |
| --- | --- |
| BR-OB-001 | `orderbook` 不依赖 `binance/internal`、`okx/internal` 或消费方 internal 包。[FRAME, HIGH] |
| BR-OB-002 | BookHash 不包含 wall clock、local receive time、map iteration order 或随机数。[COMMON, HIGH] |
| BR-OB-003 | `reliable=false` 必须阻断默认执行态消费。[FRAME, HIGH] |
| BR-OB-004 | 第二 venue conformance 通过前不得宣称跨 venue 平台完成。[INFERRED, HIGH] |
| BR-OB-005 | 首版 runtime 不创建外部连接、不读取密钥、不写远程存储。[FRAME, HIGH] |

## 5. Acceptance Criteria

| AC | Ref | Criteria |
| --- | --- | --- |
| AC-OB-001 | FR-OB-001 | Adapter contract 能表达 range sequence 与 prev-link sequence。[FRAME, HIGH] |
| AC-OB-002 | FR-OB-002 | 同一 snapshot + diff fixture 能 deterministic alignment。[FRAME, HIGH] |
| AC-OB-003 | FR-OB-003 | sequence break 触发 gap/rebuild，quality reliable=false。[FRAME, HIGH] |
| AC-OB-004 | FR-OB-004 | `qty=0` 删除价位语义可测试。[FRAME, HIGH] |
| AC-OB-005 | FR-OB-005 | BookEvent/GapEvent/QualityEvent 最小字段齐备。[FRAME, HIGH] |
| AC-OB-006 | FR-OB-006 | 同一 fixture replay 100 次 BookHash 一致。[FRAME, HIGH] |
| AC-OB-007 | FR-OB-007 | ReplayRunner 输出 BookState、BookHash、QualityTimeline。[FRAME, HIGH] |
| AC-OB-008 | FR-OB-008 | missing/duplicated/out-of-order diff 均有显式测试。[FRAME, HIGH] |
| AC-OB-009 | FR-OB-009 | stale、gap、degraded 的质量转换可测试。[FRAME, HIGH] |
| AC-OB-010 | FR-OB-010 | Binance-like fixture 可通过 conformance gate。[FRAME, HIGH] |
| AC-OB-011 | FR-OB-011 | Boundary gate 阻断禁止 import。[FRAME, HIGH] |
| AC-OB-012 | FR-OB-012 | Evidence manifest 包含命令、结果、fixture_set、hash 和 source_commit。[FRAME, HIGH] |

## 6. Dependencies

首版 runtime 只依赖 Go 标准库。[COMPUTED, HIGH]

治理依赖引用 `domain_market` 与 `domain_exchange` 作为边界方，但 runtime public API v0.1.0 不直接 import 这些仓库。[FRAME, HIGH]

## 7. Validation

```bash
cd /home/workspace/orderbook
GOWORK=off go test ./...
bash scripts/boundary-gates.sh
bash scripts/replay-determinism-gate.sh
bash scripts/gap-injection-gate.sh
```

[RULES I BROKE]：无
