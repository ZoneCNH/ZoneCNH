> ⚠️ **归档警告（v2.0.0）**：本 Task 基于旧架构（gRPC / SQLite spool / 同进程 ACK），已被 v2.0.0 分布式架构取代。
> - CLIENT-008 → 替换为 `TASK-BINANCE-CLIENT-014-natsx-publisher.md`
> - CLIENT-009 → 删除（natsx JetStream 持久化替代 spool + checkpoint）
> - SERVER-001 → 替换为 `TASK-BINANCE-SERVER-010-natsx-consumer.md`
> - SERVER-004 → 删除（natsx ManualAck 替代 gRPC ACK）
>
> 保留本文件仅供历史参考，不得作为新实现输入。

# TASK-BINANCE-CLIENT-009 Spool and Checkpoint

## Objective

Implement durable local spool and ACK-based checkpoint.

## Scope

The client persists events before send and tracks durable server acceptance.

## Deliverables

- SQLite spool schema
- checkpoint store
- state transition logic
- compaction/retention policy
- restart recovery tests

## Spool States

```text
pending
sending
acked
failed_retryable
failed_terminal
```

## Acceptance Criteria

- event is persisted before first send attempt.
- process restart preserves pending events.
- checkpoint advances only after durable server ACK.
- gRPC write success alone does not advance checkpoint.
- duplicate sends after restart are safe when paired with server idempotency.
- terminal rejects are retained or exported according to policy.

## Dependencies

- CLIENT-008 gRPC sender
- SERVER-004 ACK semantics
