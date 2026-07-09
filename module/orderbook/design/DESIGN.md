# orderbook Design

> Status: Approved
> Source Goal: GOAL-20260709-001
> Source Spec: module/orderbook/spec/SPEC.md

## 1. Module Shape

首版 runtime 是 Go library，路径 `/home/workspace/orderbook`，module path `github.com/ZoneCNH/orderbook`。[FRAME, HIGH]

## 2. Packages

| Package | 职责 |
| --- | --- |
| `pkg/event` | Snapshot、DiffEvent、BookEvent、GapEvent、QualityEvent schema。[FRAME, HIGH] |
| `pkg/adapter` | SnapshotLoader、DiffSubscriber、SequencePolicy、ExchangeSemantics。[FRAME, HIGH] |
| `pkg/book` | Book mutation、canonical price、snapshot、BookHash。[FRAME, HIGH] |
| `pkg/sync` | snapshot/diff alignment 与 state transition。[FRAME, HIGH] |
| `pkg/replay` | fixture replay、determinism、quality timeline。[FRAME, HIGH] |
| `pkg/quality` | staleness 与 quality flag policy。[FRAME, HIGH] |
| `pkg/conformance` | adapter fixture conformance runner。[FRAME, HIGH] |

## 3. Dependency Policy

Runtime 首版只使用 Go 标准库。[COMPUTED, HIGH]

领域模型通过文档边界引用 `domain_market`，不在 v0.1.0 public API 中强制 import，避免准入首日制造依赖漂移。[FRAME, HIGH]

## 4. Runtime Flow

```text
Snapshot + buffered diffs
  -> SequencePolicy / ExchangeSemantics
  -> Align
  -> Book mutation
  -> BookHash
  -> QualityTimeline / GapEvent
  -> Conformance evidence
```

[RULES I BROKE]：无
