# OrderBook Contract 与 Gate 草案

> 日期：2026-07-09
> 状态：Draft / 可迁移输入
> 目标：为后续 `module/orderbook/spec/CONTRACT.md`、`EVENT_SCHEMA.md`、`STATE_MACHINE.md` 和 `gate/*.md` 提供初版内容
> 约束：本文不创建 `module/orderbook/`，不创建 runtime repo

---

## 0. 草案边界

本文定义最小可审 contract 和 gate，不定义完整 runtime 实现。[FRAME, HIGH]

本文只允许描述跨 venue 通用语义，不允许写入 Binance 私有 REST/WS endpoint 细节。[FRAME, HIGH]

本文中的接口名称是草案，正式进入 `module/orderbook/` 前必须经过 Spec Review 和 Matrix Gate。[FRAME, HIGH]

---

## 1. Adapter Contract

### 1.1 SnapshotLoader

```go
type SnapshotLoader interface {
    LoadSnapshot(ctx context.Context, req SnapshotRequest) (Snapshot, error)
}
```

`SnapshotLoader` 负责加载 venue 的当前 depth snapshot，并返回可对齐的 `last_update_id` 或等效序列边界。[FRAME, HIGH]

### 1.2 DiffSubscriber

```go
type DiffSubscriber interface {
    SubscribeDiff(ctx context.Context, req SubscribeRequest) (<-chan DiffEvent, error)
}
```

`DiffSubscriber` 负责提供增量事件流，但不负责通用 book mutation、replay 或 quality scoring。[FRAME, HIGH]

### 1.3 SequencePolicy

```go
type SequencePolicy interface {
    Validate(prev SequencedEvent, next SequencedEvent) SequenceResult
    Align(snapshot Snapshot, buffer []DiffEvent) AlignResult
}
```

`SequencePolicy` 负责表达 venue 的 sequence continuity 语义，例如 spot `U/u` 或 futures `pu/u` 规则。[FRAME, HIGH]

### 1.4 ExchangeSemantics

```go
type ExchangeSemantics interface {
    Venue() string
    ProductLine() string
    UsesAbsoluteQty() bool
    QtyZeroMeansDelete() bool
    HasPrevSequence() bool
    HasNativeChecksum() bool
    SnapshotCanResetBook() bool
}
```

`ExchangeSemantics` 只声明语义，不执行网络请求。[FRAME, HIGH]

---

## 2. Event Schema

### 2.1 BookEvent

| 字段 | 说明 |
| --- | --- |
| `event_id` | 幂等事件 ID。[FRAME, HIGH] |
| `venue` | 交易所标识。[FRAME, HIGH] |
| `product_line` | 产品线，例如 spot、um_perp、cm_perp。[FRAME, HIGH] |
| `symbol` | venue 原生 symbol 或 canonical symbol。[FRAME, HIGH] |
| `instrument_key` | `domain_market` 的 instrument identity。[FRAME, MED] |
| `event_type` | `snapshot_load`、`level_add`、`level_update`、`level_remove` 等。[FRAME, HIGH] |
| `side` | bid / ask。[FRAME, HIGH] |
| `price` | decimal canonical string。[FRAME, HIGH] |
| `qty` | decimal canonical string。[FRAME, HIGH] |
| `sequence_start` | 事件起始 sequence。[FRAME, HIGH] |
| `sequence_end` | 事件结束 sequence。[FRAME, HIGH] |
| `prev_sequence` | 上一事件 sequence，可空。[FRAME, HIGH] |
| `book_version` | 本地 book mutation version。[FRAME, HIGH] |
| `source_snapshot_id` | 对齐所用 snapshot ID。[FRAME, MED] |
| `exchange_event_time` | venue event time。[FRAME, HIGH] |
| `local_receive_time` | 本地接收时间，不进入 deterministic hash。[FRAME, HIGH] |
| `quality_flags` | 质量标记集合。[FRAME, HIGH] |
| `schema_version` | schema version。[FRAME, HIGH] |

### 2.2 Quality Flags

```text
reliable
stale
gap_detected
gap_recovered
degraded
crossed_book
sequence_broken
snapshot_drift
replay_only
```

`reliable=false` 必须阻断执行态消费，除非消费方显式声明接受 degraded 数据。[FRAME, HIGH]

### 2.3 GapEvent

`GapEvent` 必须记录 gap 类型、触发序列、当前状态、恢复动作和下游可见性。[FRAME, HIGH]

### 2.4 QualityEvent

`QualityEvent` 必须记录 quality flag 变化、原因、影响范围和恢复条件。[FRAME, HIGH]

---

## 3. BookHash 规则

BookHash 输入必须只包含 deterministic state，不得包含 wall clock、goroutine ID、map iteration order 或本地 receive time。[COMMON, HIGH]

BookHash 输入字段建议如下。[FRAME, HIGH]

```text
venue
product_line
symbol
book_version
top_n
bids sorted desc
asks sorted asc
price decimal canonical string
qty decimal canonical string
schema_version
```

验收规则：

| 规则 | 验收 |
| --- | --- |
| 同一事件集 replay 100 次 | BookHash 完全一致。[FRAME, HIGH] |
| map iteration 顺序变化 | BookHash 不变。[COMMON, HIGH] |
| 不同机器运行 | BookHash 不变。[FRAME, HIGH] |
| local_receive_time 变化 | BookHash 不变。[FRAME, HIGH] |
| decimal 表示差异 | canonicalization 后一致。[COMMON, HIGH] |

---

## 4. State Machine

最小状态集建议如下。[FRAME, HIGH]

```text
uninit
buffering
snapshot_loading
snapshot_aligning
aligned
gap_detected
rebuilding
degraded
stale
halted
```

首版 runtime 可以映射到较小内部状态集，但对外 quality/staleness 语义必须覆盖上述状态。[FRAME, MED]

关键转移：

| From | Event | To | Downstream |
| --- | --- | --- | --- |
| `uninit` | subscribe | `buffering` | no reliable output。[FRAME, HIGH] |
| `buffering` | snapshot loaded | `snapshot_aligning` | no reliable output。[FRAME, HIGH] |
| `snapshot_aligning` | align success | `aligned` | reliable output allowed。[FRAME, HIGH] |
| `aligned` | sequence break | `gap_detected` | reliable=false。[FRAME, HIGH] |
| `gap_detected` | rebuild start | `rebuilding` | emit rebuild marker。[FRAME, HIGH] |
| `rebuilding` | align success | `aligned` | emit recovered marker。[FRAME, HIGH] |
| `rebuilding` | recovery fail | `degraded` | reliable=false。[FRAME, HIGH] |
| `degraded` | stale threshold exceeded | `stale` | execution output blocked。[FRAME, HIGH] |
| `stale` | fatal policy | `halted` | operator intervention required。[FRAME, MED] |

---

## 5. Gate 草案

### 5.1 Boundary Gate

禁止关系：

```text
orderbook -> binance/internal
orderbook -> okx/internal
orderbook -> bybit/internal
orderbook -> factor_engine/internal
orderbook -> execution/internal
orderbook -> orderx/internal
```

允许关系：

```text
binance adapter -> orderbook contract
orderbook -> domain_market
orderbook -> domain_exchange
orderbook -> decimalx
orderbook -> observex
orderbook -> resiliencx
orderbook -> testkitx
```

### 5.2 Replay Determinism Gate

输入：snapshot fixture、diff fixture、expected BookHash。[FRAME, HIGH]

通过条件：

```text
same fixture replay 100 times
BookHash identical
QualityTimeline identical
no wall clock in deterministic state
no random or map iteration dependency
```

### 5.3 Gap Injection Gate

注入类型：

```text
missing diff
duplicated diff
out-of-order diff
broken prev sequence
delayed snapshot
stale book
crossed book
```

通过条件：必须进入 gap/degraded/rebuild 语义，且不得继续输出 `reliable=true`。[FRAME, HIGH]

### 5.4 Adapter Conformance Gate

每个 adapter 必须提供：

```text
adapter_semantics.yaml
snapshot_fixture.json
diff_fixture.json
gap_fixture.json
expected_book_hash.json
expected_quality_timeline.json
```

通过条件：同一 gate 能验证至少 Binance adapter；第二 venue POC 通过前不得宣称跨 venue 平台完成。[FRAME, HIGH]

### 5.5 Evidence Gate

每次完成声明必须引用 evidence manifest。[FRAME, HIGH]

建议 evidence manifest 字段：

```text
contract_version
schema_version
adapter
fixture_set
test_command
test_result
book_hash
quality_timeline_hash
created_at
source_commit
```

---

## 6. Traceability Seed

| Requirement | Description | Acceptance Criteria | Test Case / Gate | Task | Status |
| --- | --- | --- | --- | --- | --- |
| FR-OB-001 | Adapter Contract | AC-OB-001 | Adapter Conformance Gate | TASK-OB-001 | Pending |
| FR-OB-002 | Snapshot/Diff Alignment | AC-OB-002 | Replay Gate | TASK-OB-002 | Pending |
| FR-OB-003 | Sequence Validation | AC-OB-003 | Gap Injection Gate | TASK-OB-003 | Pending |
| FR-OB-004 | BookEvent Schema | AC-OB-004 | Schema fixture test | TASK-OB-004 | Pending |
| FR-OB-005 | BookHash Determinism | AC-OB-005 | Replay Determinism Gate | TASK-OB-005 | Pending |
| FR-OB-006 | Quality Flags | AC-OB-006 | Quality timeline test | TASK-OB-006 | Pending |
| FR-OB-007 | Boundary Rules | AC-OB-007 | Boundary Gate | TASK-OB-007 | Pending |
| BR-OB-001 | No unauthorized module creation | AC-OB-008 | Governance Gate | TASK-OB-008 | Pending |

---

## 7. 迁移条件

本文可迁移到 `module/orderbook/` 的条件如下。[FRAME, HIGH]

```text
治理层批准 orderbook 准入 ADR
人工在当前会话显式授权创建 module/orderbook
binance Phase 1 前置硬化至少完成 shard planner 与 DepthLevel 语义回归
正式 Spec owner 确认首版 arch_type
```

---

[RULES I BROKE]：无
