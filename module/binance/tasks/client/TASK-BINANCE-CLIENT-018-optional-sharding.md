# TASK-BINANCE-CLIENT-018 可选：一致性哈希分片（GAP-E25）

> ⚠️ **OPTIONAL 任务**：本任务为分级（CLIENT-017）落地后的**可选扩容路径**，非必做。依据 EXCHANGEINFO 报告 §8.2 勘误（ADR-005 §6.2），分级后单副本负载 ~940 stream（2 WS 连接）通常足够，**仅在业务增长到单副本扛不住时才启用本任务**。
>
> 版本：v1.0.0
> 关联缺口：GAP-E25（CRITICAL，§8.2 勘误降为可选）
> 关联设计：ADR-005 §6.2/§8.2；TIER-DESIGN-DETAILS §9

## Objective（可选）

实现一致性哈希分片 + ClientID 机制，使多副本 client 各自只采自己分片内的 symbol，避免重复采集。

> ⚠️ **前置评估**：实施前必须先量化单副本负载（参考 ADR-005 §3.2 推算口径），确认确实需要分片。若单副本 WS ≤ 940 stream 且 REST 冷启动 ≤ 8h，**不应启用本任务**。

## 触发条件（何时启用本任务）

仅当下列任一阈值被触发时，才评估启用本任务：

| 触发条件 | 阈值 | 说明 |
|----------|------|------|
| 单副本 WS stream 数 | > 2000 | 逼近 2 连接上限（1024×2=2048） |
| REST 冷启动 backfill | > 8h | 单副本 T3 ~60K 请求已近极限 |
| 业务 symbol 增长 | T2 扩容超 500 | 分级配置已无法用单副本承载 |

未触发任一阈值时，本任务保持 deferred 状态。

## Scope

### scope_in

```text
internal/client/sharding/
  client_id.go           ← ClientID 生成与注册（启动注册 + NATS heartbeat）
  ring.go                ← 一致性哈希 ring（虚节点 200/client）
  assigner.go            ← symbol→ClientID 映射 + 副本增减重分片 + diff 广播
```

### scope_out

- 不动 Tier 分级逻辑（CLIENT-017 是前置）
- 不动 catalog 字段结构
- 不动 server 端 ingest/存储路径（SERVER-018 独立提供 shard_id 列）

## 接口设计

```go
// internal/client/sharding/client_id.go
type ClientID string // UUIDv4，进程启动生成，向 server 注册

// internal/client/sharding/ring.go
type Ring struct {
    vnodes int               // 200/client
    hash   func(string) uint32 // fnv32
    nodes  []uint32           // sorted virtual hashes
    owners map[uint32]ClientID
}
// Owner(symbol) ClientID — 一致性哈希查表，决定 symbol 由哪个副本采集

// internal/client/sharding/assigner.go
// 副本增减触发重分片，heartbeat timeout 30s 缓冲后重建 ring，diff 广播到 NATS。
```

## Functional Requirements

**FR-018-001**: WHEN client 启动 THEN 生成唯一 ClientID（UUIDv4）并向 server 注册，启动 NATS heartbeat（10s 间隔）。

**FR-018-002**: WHEN catalog 给定 symbol 集合 THEN 一致性哈希 ring（虚节点 200/client）决定每个 symbol 由哪个副本采集，本副本只订阅 Owner(symbol) == self 的子集。

**FR-018-003**: WHEN 副本增减（heartbeat timeout 30s 缓冲后判定离线）THEN 触发重分片，重建 ring 并广播 owned-diff，确保无采集中断。

**FR-018-004**: WHEN 新副本加入 THEN 仅承担 forward（增量）采集，**不触发历史 backfill 雪崩**（历史数据由原 owner 完成，新副本从最新时间戳接管）。

## Acceptance Criteria

> 映射关系：本 task 为可选任务（deferred），**暂不映射 AC-TIER**（见 ACCEPTANCE.md §2.1 声明——待启用时补 AC-TIER-007/008）。下列 AC-018-* 为 task-local 验收。

| AC | 验证方式 | 映射 AC-TIER |
|----|---------|--------------|
| AC-018-001 | 3 副本部署时，同一 symbol 仅被 1 个副本采集（grep 3 副本订阅列表交集为空） | 无（task-local，待启用补 AC-TIER-007） |
| AC-018-002 | 副本缩容（3→2）后，剩余副本在 30s heartbeat timeout 内接管离线副本的分片，无采集中断（NATS 流量无 gap） | 无（task-local，待启用补 AC-TIER-008） |

## Dependencies（可选）

> 本任务为可选，依赖项亦为可选启用条件。

| 依赖 | 用途 | 性质 |
|------|------|------|
| CLIENT-017（Tier 分级） | 前置，提供 T0~T3 配置 | 必须前置（但 CLIENT-017 本身必做） |
| GAP-E10（NATS 通道） | heartbeat 与 diff 广播通道 | 必须前置 |
| GAP-E31（NATS 拓扑配置化） | Stream/Subject/AckWait 配置化 | 必须前置 |
| SERVER-018（shard_id 列） | server 端记录采集副本 | 同 PR 落地 |

## Non-scope

- 不做 Tier 分级配置（CLIENT-017）
- 不做 server 端完整性对账（GAP-E2/E3）
- 不做 backfill 任务迁移（新副本只接 forward）
