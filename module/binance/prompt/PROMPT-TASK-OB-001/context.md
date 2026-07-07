# PROMPT-TASK-OB-001 Context Packet

- Task: TASK-OB-001 (Order Book 状态机核心)
- Target: `/home/workspace/binance`
- FR: FR-052
- AC: AC-OB-001
- TC: TC-OB-001
- Design: [ORDER-BOOK-STATE-MACHINE.md](../../design/ORDER-BOOK-STATE-MACHINE.md) §3-§4, §6
- ADR: [ADR-011](../../design/ADR-011-order-book-rebuild-inclusion.md)

## Context

在 `internal/client/orderbook/` 下实现 per-symbol order book 状态机核心。这是 v4.0.0 order book rebuild 功能的基础组件，后续 task（对齐算法、序号校验、持久化、对外接口）都依赖此核心。

状态机有 4 个状态：UNINITIALIZED → BUFFERING → ALIGNED → REBUILDING，每个 symbol 一个独立 goroutine，无全局锁。

## Files to Create

| File | Action | Purpose |
|------|--------|---------|
| `internal/client/orderbook/manager.go` | Create | OrderBookManager: per-symbol 状态机生命周期管理 |
| `internal/client/orderbook/state.go` | Create | State 枚举 + 状态转换 guard/action |
| `internal/client/orderbook/book.go` | Create | Book: 有序价格→数量结构 |
| `internal/client/orderbook/book_test.go` | Create | Book 结构单元测试 |
| `internal/client/orderbook/manager_test.go` | Create | 状态机转换单元测试 |

## Key Types

```go
// state.go

type State int

const (
    StateUninitialized State = iota  // 未订阅，无数据
    StateBuffering                    // WS 活跃，缓冲事件中，REST 快照待发
    StateAligned                      // book 有效，增量更新通过序号校验
    StateRebuilding                   // gap 检测，丢弃 book，回到 BUFFERING
)

// String implements fmt.Stringer for logging/metrics.
func (s State) String() string

// CanTransitionTo returns true if the transition from→to is valid per the state machine.
func (s State) CanTransitionTo(target State) bool

// Stale returns true for all states except StateAligned.
func (s State) Stale() bool


// book.go

// Book is a per-symbol order book with ordered bid/ask sides.
// Uses a sorted map (red-black tree equivalent) for O(logN) insert/delete
// and O(1) TopN retrieval via maintained best-N pointers.
type Book struct {
    symbol       string
    productLine  string
    bids         *bookSide  // sorted descending by price
    asks         *bookSide  // sorted ascending by price
    lastUpdateID int64
    updateTime   time.Time
}

// bookSide is one side of the order book (bids or asks).
type bookSide struct {
    // Implementation: use a sorted slice with binary search,
    // or a rbtree/skiplist if available in the codebase.
    // Start simple (sorted slice + sort.Search), optimize later if benchmark requires.
}

// ApplyLevel updates or removes a single price level.
// If qty == "0", removes the price level (delete, not zero-set).
// Price is converted to a fixed-point key using tickSize alignment.
func (b *Book) ApplyLevel(side string, price string, qty string, tickSize string) error

// TopN returns the top N bid and ask levels.
func (b *Book) TopN(n int) (bids []BookLevel, asks []BookLevel)

// Snapshot returns a deep copy of the entire book.
func (b *Book) Snapshot() *BookSnapshot

// LastUpdateID returns the last applied update ID.
func (b *Book) LastUpdateID() int64

// UpdateTime returns the timestamp of the last applied update.
func (b *Book) UpdateTime() time.Time


// manager.go

// OrderBookManager manages per-symbol order book state machines.
// Each symbol gets its own goroutine with independent state.
type OrderBookManager struct {
    books map[string]*symbolBook  // key: symbol
    mu    sync.RWMutex            // only protects map access, NOT book state
}

// symbolBook is a per-symbol order book with its own goroutine.
type symbolBook struct {
    symbol      string
    productLine string
    state       atomic.Int32      // State as int32
    book        *Book             // only valid when state == ALIGNED
    buffer      []bufferedEvent   // WS events buffered during BUFFERING
    eventCh     chan NormalizedEvent  // WS events from connector
    stopCh      chan struct{}

    // Atomic flags for external readers (no lock needed)
    stale           atomic.Bool
    lastUpdateTime  atomic.Int64   // unix nano
    lastRebuildTime atomic.Int64   // unix nano
}

// Subscribe starts a new order book state machine for the given symbol.
func (m *OrderBookManager) Subscribe(ctx context.Context, symbol string, productLine string, events <-chan NormalizedEvent) error

// Unsubscribe stops the order book for the given symbol.
func (m *OrderBookManager) Unsubscribe(symbol string) error

// GetState returns the current state and staleness of a symbol's book.
func (m *OrderBookManager) GetState(symbol string) (state State, stale bool, lastUpdate time.Time, lastRebuild time.Time)

// GetBook returns a snapshot of the current book (nil if not ALIGNED).
func (m *OrderBookManager) GetBook(symbol string) *BookSnapshot
```

## Existing Types to Reference

```go
// internal/client/normalize.go — already exists
type NormalizedEvent struct {
    ProductLine      string
    SourceStream     string
    Symbol           string
    EventType        string
    EventTime        time.Time
    LocalReceiveTime time.Time
    RawPayload       []byte
    Depth   DepthFields
    // ... other event-type fields
}

type DepthFields struct {
    FirstUpdateID    int64   // U
    FinalUpdateID    int64   // u
    PreviousUpdateID int64   // pu (futures only, 0 for spot)
    UpdateID         int64   // bookTicker update ID
    DepthBids        []BookLevel
    DepthAsks        []BookLevel
}

type BookLevel struct {
    Price string
    Qty   string
}
```

## State Transition Matrix

Implement exactly per [STATE-MACHINE.md §4.1](../../design/ORDER-BOOK-STATE-MACHINE.md):

| From | To | Trigger | Guard | Action |
|------|----|---------|-------|--------|
| UNINITIALIZED | BUFFERING | subscribe() | — | init buffer, start goroutine |
| BUFFERING | ALIGNED | alignment success | first valid event: U <= lastUpdateId+1 <= u | apply buffer, clear buffer |
| BUFFERING | BUFFERING | REST too old | lastUpdateId < buffer[0].U | re-request REST |
| BUFFERING | BUFFERING | buffer overflow | len(buffer) > 10000 | discard buffer, re-request REST |
| ALIGNED | REBUILDING | seq fail | spot: U != u+1; futures: pu != u | discard book |
| ALIGNED | REBUILDING | WS disconnect | — | discard book |
| REBUILDING | BUFFERING | immediate | — | keep WS, re-request REST |
| ALIGNED | UNINITIALIZED | unsubscribe() | — | close goroutine |
| BUFFERING | UNINITIALIZED | unsubscribe() | — | close goroutine |

> **Note**: TASK-OB-001 only implements the state machine skeleton + Book structure. The actual alignment algorithm (BUFFERING→ALIGNED) and sequence validation (ALIGNED→REBUILDING) are TASK-OB-002 and TASK-OB-003. In OB-001, use placeholder hooks:
> - `alignBook()` → `// TODO: TASK-OB-002`
> - `validateSequence()` → `// TODO: TASK-OB-003`

## Concurrency Model

```
Per-symbol goroutine:
  for {
    select {
    case event := <-eventCh:
      handleEvent(event)  // state-dependent processing
    case <-stopCh:
      return
    }
  }

External readers (GetState/GetBook):
  - Use atomic reads (atomic.Int32 for state, atomic.Bool for stale)
  - Book snapshot uses COW or sync.RWMutex read lock
  - NEVER block the event goroutine
```

## Constraints

1. **No global lock**: each symbol's goroutine is independent. The manager's `sync.RWMutex` only protects the `books` map, not any book's internal state.
2. **Event channel buffer**: 1024. If full, drop oldest event, set stale=true, trigger REBUILDING.
3. **Book data structure**: start with sorted slice + `sort.Search` for simplicity. If benchmark shows bottleneck, upgrade to rbtree/skiplist. Don't prematurely optimize.
4. **Price precision**: convert price string to fixed-point using tickSize. Do NOT use float64. Use `shopspring/decimal` or string-based comparison if available; otherwise implement a simple fixed-point converter.
5. **qty == "0"** means DELETE the price level, not set quantity to zero.
6. **REBUILDING is transient**: < 1ms, immediately transitions to BUFFERING. No external observer should see REBUILDING state persist.
7. **Package boundary**: `orderbook` package may import `normalize` types but must NOT import `server` packages.
8. **No external dependencies**: use only stdlib + existing codebase packages. If a sorted map library is needed, vendor it or implement inline.

## Acceptance Criteria (AC-OB-001)

- [ ] 4 states defined with correct String() representation
- [ ] CanTransitionTo() validates all 9 transitions per the matrix
- [ ] Stale() returns true for non-ALIGNED states
- [ ] per-symbol goroutine: events processed FIFO, no cross-symbol blocking
- [ ] Book: ApplyLevel updates/deletes correctly (qty=="0" deletes)
- [ ] Book: TopN returns correct ordered levels
- [ ] Book: Snapshot returns deep copy (mutation of copy doesn't affect original)
- [ ] Manager: Subscribe creates goroutine, Unsubscribe stops it cleanly
- [ ] Manager: GetState returns atomic snapshot (no race with event goroutine)
- [ ] Manager: GetBook returns nil when not ALIGNED

## Test Cases (TC-OB-001)

```go
// manager_test.go

func TestState_CanTransitionTo(t *testing.T) {
    // Verify all 9 valid transitions
    // Verify invalid transitions return false
}

func TestState_Stale(t *testing.T) {
    // Uninitialized/Buffering/Rebuilding → true
    // Aligned → false
}

func TestBook_ApplyLevel(t *testing.T) {
    // Add bid at 50000.10 qty 1.5 → present in TopN
    // Update bid at 50000.10 qty 2.0 → quantity changed
    // Delete bid at 50000.10 qty "0" → absent from TopN
    // Precision: 50000.1 and 50000.10 are same level (tickSize alignment)
}

func TestBook_TopN(t *testing.T) {
    // Bids sorted descending, asks sorted ascending
    // TopN(5) returns at most 5 per side
    // TopN(0) returns empty
}

func TestBook_Snapshot(t *testing.T) {
    // Modify snapshot → original book unaffected
}

func TestManager_SubscribeUnsubscribe(t *testing.T) {
    // Subscribe → state=BUFFERING, goroutine running
    // Unsubscribe → goroutine stopped, state=UNINITIALIZED
    // Double unsubscribe → no panic
}

func TestManager_PerSymbolGoroutine(t *testing.T) {
    // Two symbols: slow processing on one doesn't block the other
    // Events to symbol A's channel don't affect symbol B
}

func TestManager_GetState(t *testing.T) {
    // Before subscribe → UNINITIALIZED, stale=true
    // After subscribe → BUFFERING, stale=true
    // Concurrent reads don't race with event processing
}

func TestManager_EventChannelFull(t *testing.T) {
    // Fill channel to capacity → next event drops oldest
    // Stale flag set to true
    // State transitions to REBUILDING → BUFFERING
}
```

## Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| `internal/client/normalize.go` | existing | NormalizedEvent, DepthFields, BookLevel types |
| `sync`, `sync/atomic` | stdlib | concurrency primitives |
| `sort` | stdlib | binary search for sorted slice |
| `time` | stdlib | timestamps |
| `context` | stdlib | goroutine lifecycle |
| `fmt` | stdlib | String() methods, error formatting |

## Non-scope

- REST snapshot fetching (TASK-OB-002)
- Sequence validation logic (TASK-OB-003)
- Auto-rebuild REST retry (TASK-OB-004)
- Snapshot persistence (TASK-OB-005)
- Staleness API HTTP endpoints (TASK-OB-006)
- TopN subscription (TASK-OB-007)
- Incremental forwarding (TASK-OB-008)
- Alerting + checksum (TASK-OB-009)
- snapshot_topn mode (TASK-OB-010)
- Integration tests (TASK-OB-011)

## Verification

```bash
cd /home/workspace/binance
go test ./internal/client/orderbook/... -race -count=1 -v
go vet ./internal/client/orderbook/...
golangci-lint run ./internal/client/orderbook/...
```
