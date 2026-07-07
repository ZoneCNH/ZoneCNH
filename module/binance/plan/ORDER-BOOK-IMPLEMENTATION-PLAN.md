# Order Book Implementation Task Breakdown

> 状态：Plan
> 来源：[ADR-011](../design/ADR-011-order-book-rebuild-inclusion.md) + [ORDER-BOOK-STATE-MACHINE.md](../design/ORDER-BOOK-STATE-MACHINE.md)
> SPEC：v4.0.0 FR-052~061
> Last-Updated：2026-07-06

## 1. Task 依赖图

```
TASK-OB-001 (状态机核心)
    │
    ├──▶ TASK-OB-002 (Initial Alignment + 对齐算法)
    │       │
    │       └──▶ TASK-OB-003 (Sequence Validation + qty==0 + 精度)
    │               │
    │               └──▶ TASK-OB-004 (Auto-Rebuild + buffer cap)
    │
    ├──▶ TASK-OB-005 (Snapshot Persistence + Fast Recovery)
    │
    ├──▶ TASK-OB-006 (Staleness API + Health Query)
    │       │
    │       ├──▶ TASK-OB-007 (TopN Subscription)
    │       │
    │       └──▶ TASK-OB-008 (Incremental Forwarding)
    │
    ├──▶ TASK-OB-009 (Rebuild Alerting + Checksum)
    │
    └──▶ TASK-OB-010 (snapshot_topn 模式)

TASK-OB-011 (集成测试 + boundary gates) — 依赖全部
```

## 2. Task 清单

| Task | FR | AC | 依赖 | 预估 | 优先级 |
|------|----|----|------|------|--------|
| TASK-OB-001 | FR-052 | AC-OB-001 | — | 3d | P0 |
| TASK-OB-002 | FR-054 | AC-OB-003 | OB-001 | 2d | P0 |
| TASK-OB-003 | FR-054 | AC-OB-004,005 | OB-002 | 2d | P0 |
| TASK-OB-004 | FR-055 | AC-OB-006 | OB-003 | 1d | P0 |
| TASK-OB-005 | FR-056 | AC-OB-007 | OB-001 | 2d | P1 |
| TASK-OB-006 | FR-057,060 | AC-OB-008,011 | OB-001 | 1d | P1 |
| TASK-OB-007 | FR-058 | AC-OB-009 | OB-006 | 1d | P1 |
| TASK-OB-008 | FR-059 | AC-OB-010 | OB-006 | 1d | P1 |
| TASK-OB-009 | FR-061 | AC-OB-012 | OB-004 | 1d | P2 |
| TASK-OB-010 | FR-053 | AC-OB-002 | OB-001 | 1d | P2 |
| TASK-OB-011 | — | — | OB-001~010 | 2d | P0 |

## 3. Task 详细规格

### TASK-OB-001: Order Book 状态机核心

**FR**: FR-052
**AC**: AC-OB-001
**Scope**:
```
internal/client/orderbook/
  manager.go           ← OrderBookManager: per-symbol 状态机管理
  state.go             ← State 枚举 + 转换矩阵
  book.go              ← Book: 有序价格→数量结构（红黑树/跳表）
  book_test.go
  manager_test.go
```

**关键设计**:
- per-symbol goroutine，无全局锁
- 4 状态：UNINITIALIZED / BUFFERING / ALIGNED / REBUILDING
- 状态转换 guard/action 按 STATE-MACHINE.md §4.1 转换矩阵
- Book 结构：红黑树或跳表，支持 O(logN) 插入/删除 + O(1) TopN 取出
- 事件 channel：缓冲 1024，满则丢弃最旧 + 标记 stale

**验收**: TC-OB-001

---

### TASK-OB-002: Initial Alignment 对齐算法

**FR**: FR-054
**AC**: AC-OB-003
**依赖**: OB-001
**Scope**:
```
internal/client/orderbook/
  alignment.go         ← 9步对齐算法
  alignment_test.go
```

**关键设计**:
- BUFFERING → ALIGNED 转换核心
- REST 快照请求 + buffer 对齐
- 快照太旧（lastUpdateId < buffer[0].U）→ 重新拉 REST
- 对齐失败（gap between snapshot and buffer）→ 重新拉 REST
- 对齐成功 → 初始化 book + 应用 buffer + 清空 buffer → ALIGNED

**验收**: TC-OB-002

---

### TASK-OB-003: Sequence Validation + 档位删除 + 精度

**FR**: FR-054
**AC**: AC-OB-004, AC-OB-005
**依赖**: OB-002
**Scope**:
```
internal/client/orderbook/
  sequence.go          ← 序号校验（spot U/u + futures U/u/pu）
  sequence_test.go
  book.go (扩展)       ← qty=="0" 删除 + 定点数价格对齐
```

**关键设计**:
- spot: `新U == 旧u + 1`；futures: `新pu == 旧u`
- 校验失败 → REBUILDING
- qty == "0" → delete book[price]（不是设为 0）
- 价格用字符串转定点数，按 tickSize 对齐

**验收**: TC-OB-003, TC-OB-004

---

### TASK-OB-004: Auto-Rebuild + Buffer Cap

**FR**: FR-055
**AC**: AC-OB-006
**依赖**: OB-003
**Scope**:
```
internal/client/orderbook/
  rebuild.go           ← REBUILDING → BUFFERING 转换 + buffer cap
  rebuild_test.go
```

**关键设计**:
- gap → 丢弃 book → REBUILDING → BUFFERING（保留 WS 订阅）
- buffer cap（默认 10000）→ 溢出时丢弃全部 → 重新拉 REST
- REST 快照失败 → 指数退避重试（最大 3 次）→ 保持 BUFFERING + stale=true

**验收**: TC-OB-005

---

### TASK-OB-005: Snapshot Persistence + Fast Recovery

**FR**: FR-056
**AC**: AC-OB-007
**依赖**: OB-001
**Scope**:
```
internal/client/orderbook/
  snapshot_store.go    ← 持久化 + 恢复
  snapshot_store_test.go
```

**关键设计**:
- 定期（5min）book → TDengine/OSS 序列化
- 冷启动 fast path：加载快照 → BUFFERING → 验证序列连续性
  - 命中 → ALIGNED（O(1)）
  - 不命中 → 降级完整重建
- 持久化不阻塞 ALIGNED 事件处理（只读拷贝）

**验收**: TC-OB-006

---

### TASK-OB-006: Staleness API + Health Query

**FR**: FR-057, FR-060
**AC**: AC-OB-008, AC-OB-011
**依赖**: OB-001
**Scope**:
```
internal/client/orderbook/
  health.go            ← stale 标记 + last_update + last_rebuild + 健康查询
  health_test.go
```

**关键设计**:
- `stale = atomic.Bool` = `(state != ALIGNED)`
- `last_update_time = atomic.Int64`（unix nano）
- `last_rebuild_time = atomic.Int64`
- 按需全量快照：返回 book 只读拷贝 + stale 标记
- 健康查询：返回 `{ symbol, state, stale, last_update, last_rebuild, lastUpdateId }`

**验收**: TC-OB-007, TC-OB-010

---

### TASK-OB-007: TopN Subscription

**FR**: FR-058
**AC**: AC-OB-009
**依赖**: OB-006
**Scope**:
```
internal/client/orderbook/
  topn.go              ← 固定频率 TopN 推送
  topn_test.go
```

**关键设计**:
- 推送频率：配置项（默认 100ms）
- ALIGNED：取 TopN + stale=false
- 非 ALIGNED：最后已知值 + stale=true（继续推送，不停止）

**验收**: TC-OB-008

---

### TASK-OB-008: Incremental Forwarding

**FR**: FR-059
**AC**: AC-OB-010
**依赖**: OB-006
**Scope**:
```
internal/client/orderbook/
  forwarding.go        ← 已校验增量转发 + rebuild 标记事件
  forwarding_test.go
```

**关键设计**:
- ALIGNED：原样转发已校验增量 `{ U, u, pu, bids, asks, stale: false }`
- REBUILDING：推 `{ type: "rebuild_start", stale: true }`
- ALIGNED 恢复：推 `{ type: "rebuild_complete", stale: false, lastUpdateId }`

**验收**: TC-OB-009

---

### TASK-OB-009: Rebuild Alerting + Checksum Sampling

**FR**: FR-061
**AC**: AC-OB-012
**依赖**: OB-004
**Scope**:
```
internal/client/orderbook/
  alerting.go          ← 重建频率告警 + checksum 抽样
  alerting_test.go
```

**关键设计**:
- 5min 内 >3 次 REBUILDING → emit alert
- 1min 定期 REST 快照 vs 内存 book diff
- diff != empty → alert + REBUILDING

**验收**: TC-OB-011

---

### TASK-OB-010: snapshot_topn 模式

**FR**: FR-053
**AC**: AC-OB-002
**依赖**: OB-001
**Scope**:
```
internal/client/orderbook/
  snapshot_topn.go     ← 无状态限档快照转发
  snapshot_topn_test.go
```

**关键设计**:
- 订阅 `<symbol>@depth5/@depth10/@depth20`
- 每条事件是完整 TopN 快照，不需序号校验
- 不进 REBUILDING 状态
- WS 断连 → stale=true

**验收**: TC-OB-001（扩展）

---

### TASK-OB-011: 集成测试 + Boundary Gates

**依赖**: OB-001~010
**Scope**:
```
test/integration/
  orderbook_e2e_test.go    ← 全链路：WS → 状态机 → TopN/增量转发 → 健康查询
  orderbook_rebuild_test.go ← gap 触发重建 + 持久化恢复
scripts/
  boundary-gates.sh (扩展)  ← order book 组件边界检查
```

**关键设计**:
- 端到端：mock Binance WS + REST → 验证全状态机流转
- 重建场景：注入 gap → 验证 REBUILDING → BUFFERING → ALIGNED
- 持久化场景：正常运行 → 关闭 → 重启 → fast path 恢复
- boundary gate：order book 包不导入 server 包

**验收**: 全部 TC-OB-001~011

## 4. 实现顺序

```
Phase 1 (P0, 8d): 核心状态机 + 对齐 + 校验 + 重建
  OB-001 → OB-002 → OB-003 → OB-004 → OB-011(部分)

Phase 2 (P1, 5d): 持久化 + 对外接口
  OB-005 → OB-006 → OB-007 → OB-008 → OB-011(部分)

Phase 3 (P2, 3d): 告警 + snapshot_topn + 集成测试
  OB-009 → OB-010 → OB-011(完整)
```

## 5. 前置条件

| 条件 | 状态 | 阻塞 |
|------|------|------|
| ADR-011 Accepted | Proposed | 阻塞全部（需 spec-review 通过） |
| options depth 实测 | 未开始 | 阻塞 options 范围（不阻塞 spot/um/cm） |
| RUNTIME-MAPPING.md order book 路径 | ✅ 已添加 | — |
| STATE-MACHINE.md 设计完成 | ✅ 已完成 | — |

## 6. 风险

| 风险 | 级别 | 缓解 |
|------|------|------|
| Book 数据结构选型影响性能 | Medium | 红黑树 vs 跳表 benchmark 后决定 |
| REST 快照与 WS 时间窗口竞争 | High | 9步对齐算法已覆盖，buffer cap 防溢出 |
| options depth 协议未知 | Medium | 先实现 spot/um/cm，options 后补 |
| 内存占用随 symbol 数线性增长 | Medium | 分级体系（ADR-005）限制 full_incremental symbol 数 |
